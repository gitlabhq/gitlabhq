# frozen_string_literal: true

module Authn
  module TokenField
    class Digest < Base
      RehashError = Class.new(StandardError)

      # During a key rotation, nodes disagree on the current key and would
      # otherwise rewrite a token's digest back and forth on every request.
      REHASH_LEASE_TIMEOUT = 10.minutes.to_i

      def token_fields
        super + [token_field_name]
      end

      def find_token_authenticatable(token, unscoped = false, uniqueness_check: false)
        return unless token

        # With every db_key_base key, to find tokens digested before a rotation
        token_owner_record = relation(unscoped).find_by(token_field_name => encode_candidates(token)) # rubocop:disable CodeReuse/ActiveRecord: -- This is meant to be used in AR models.
        rehash_digest(token_owner_record, encode(token)) if token_owner_record && !uniqueness_check

        token_owner_record
      end

      def get_token(token_owner_record)
        token_owner_record.cleartext_tokens&.[](token_field)
      end

      def encode(token)
        Gitlab::CryptoHelper.sha256(token)
      end

      def encode_candidates(token)
        Gitlab::CryptoHelper.sha256_candidates(token)
      end

      def set_token(token_owner_record, token)
        return unless token

        token_owner_record.cleartext_tokens ||= {}
        token_owner_record.cleartext_tokens[token_field] = token
        token_owner_record[token_field_name] = encode(token)
      end

      protected

      def token_set?(token_owner_record)
        token_owner_record.read_attribute(token_field_name).present?
      end

      def token_field_name
        "#{token_field}_digest"
      end

      # A digest written with an older `db_key_base` key is rewritten with the
      # current key on use, so the older key can be retired. Never fails the lookup.
      def rehash_digest(token_owner_record, current_digest)
        stored_digest = token_owner_record.read_attribute(token_field_name)
        return if stored_digest == current_digest
        return if Gitlab::Database.read_only? || token_owner_record.frozen?
        # A failed write would abort the caller's transaction, and the lease raises
        # in development when any database has one open.
        return if inside_transaction?
        return unless rehash_lease(token_owner_record).try_obtain

        Gitlab::Database::QueryAnalyzers::PreventWritesOnGet.allow_write_on_get(
          url: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/631700') do
          session = ::Gitlab::Database::LoadBalancing::SessionMap.current(token_owner_record.load_balancer)
          session.without_sticky_writes do
            # Matching the stored digest keeps a stale read from reviving a token reset since.
            # rubocop:disable CodeReuse/ActiveRecord -- This is meant to be used in AR models.
            updated = token_owner_record.class.unscoped
              .where(token_owner_record.class.primary_key => token_owner_record.id, token_field_name => stored_digest)
              .update_all(token_field_name => current_digest)
            # rubocop:enable CodeReuse/ActiveRecord

            log_rehash(token_owner_record) if updated > 0
          end
        end
      rescue ActiveRecord::ActiveRecordError, ::Redis::BaseError => e
        # The message can carry the digest, e.g. in a unique violation's DETAIL.
        error = RehashError.new(e.class.name).tap { |rehash_error| rehash_error.set_backtrace(e.backtrace) }
        Gitlab::ErrorTracking.track_exception(error, token_field: token_field_name)
      end

      private

      # The same check as Gitlab::ExclusiveLease#try_obtain
      def inside_transaction?
        ::ApplicationRecord.inside_transaction? ||
          ::Gitlab::Database.database_base_models.values
            .reject { |model| model == ActiveRecord::Base }.any?(&:inside_transaction?)
      end

      def rehash_lease(token_owner_record)
        Gitlab::ExclusiveLease.new(
          "token_digest_rehash:#{token_owner_record.class.table_name}:#{token_owner_record.id}",
          timeout: REHASH_LEASE_TIMEOUT
        )
      end

      def log_rehash(token_owner_record)
        Gitlab::AuthLogger.info(
          message: 'Token digest rehashed with the current db_key_base key',
          Labkit::Fields::CLASS_NAME => self.class.name,
          token_owner_type: token_owner_record.class.name,
          token_owner_id: token_owner_record.id,
          token_field: token_field_name
        )
      end
    end
  end
end
