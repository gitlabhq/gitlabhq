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

          # TODO: remove this logging once the following issue is resolved
          # https://gitlab.com/gitlab-org/gitlab/-/work_items/599571
          Gitlab::AppLogger.info(
            Labkit::Fields::CLASS_NAME => self.class.name,
            Labkit::Fields::LOG_MESSAGE => "Partition pruning missed, falling back to all partitions query",
            has_prefix: ::Authn::AgnosticTokenIdentifier::TOKEN_TYPES.find { |t| t.prefix?(token) }.try(:to_s),
            partition_key: partition_key
          )

          base_scope
            .find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by
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
