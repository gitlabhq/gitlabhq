# frozen_string_literal: true

module Authn
  module TokenField
    module Finders
      class BaseEncryptedPartitioned < BaseEncrypted
        def execute
          if partition_key.present?
            record = partition_scope.find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by
            return record if record
          end

          return if skip_fallback?

          fallback_record = base_scope
            .find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by

          # TODO: remove this logging once the following issue is resolved
          # https://gitlab.com/gitlab-org/gitlab/-/work_items/599571
          # NOTE: only derived metadata is logged below; never log the token or any portion of it.
          Gitlab::AppLogger.info(
            Labkit::Fields::CLASS_NAME => self.class.name,
            Labkit::Fields::LOG_MESSAGE => "Partition pruning missed, falling back to all partitions query",
            has_prefix: ::Authn::AgnosticTokenIdentifier::TOKEN_TYPES.find { |t| t.prefix?(token) }.try(:to_s),
            partition_key: partition_key,
            fallback_record_id: fallback_record&.id,
            fallback_record_partition_id: fallback_record.try(:partition_id),
            token_length: token.to_s.length,
            token_dot_count: token.to_s.count('.')
          )

          fallback_record
        end

        protected

        def skip_fallback?
          false
        end

        def partition_key
          raise NotImplementedError
        end

        def partition_scope
          raise NotImplementedError
        end
      end
    end
  end
end
