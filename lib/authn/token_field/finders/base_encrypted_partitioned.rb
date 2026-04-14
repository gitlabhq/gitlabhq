# frozen_string_literal: true

module Authn
  module TokenField
    module Finders
      class BaseEncryptedPartitioned < BaseEncrypted
        def execute
          if partition_key.present?
            record = partition_scope.find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by
            return record if record

            # TODO: remove this logging once the following issue is resolved
            # https://gitlab.com/gitlab-org/gitlab/-/work_items/594564
            Gitlab::AppLogger.info(
              class: self.class.name,
              message: "Partition pruning fast-path miss: record not found in decoded partition",
              record_class: base_scope.model.name,
              partition_key: partition_key
            )
          else
            # TODO: remove this logging once the following issue is resolved
            # https://gitlab.com/gitlab-org/gitlab/-/work_items/594564
            Gitlab::AppLogger.info(
              class: self.class.name,
              message: "Partition pruning skipped: partition_key is blank",
              record_class: base_scope.model.name,
              token_prefix: token.to_s[0, 10] # only the non-secret prefix portion
            )
          end

          base_scope
            .find_by(encrypted_field => tokens) # rubocop:disable CodeReuse/ActiveRecord -- have to use find_by
            # TODO: remove this logging once the following issue is resolved
            # https://gitlab.com/gitlab-org/gitlab/-/work_items/594564
            .tap do |record|
              if record.blank?
                Gitlab::AppLogger.info(
                  class: self.class.name,
                  message: "Partition pruning fallback: record not-found",
                  record_class: base_scope.model.name,
                  partition_key: partition_key
                )
              else
                Gitlab::AppLogger.info(
                  class: self.class.name,
                  message: "Partition pruning fallback: found record",
                  record_class: record.class,
                  record_id: record.id,
                  record_partition_id: record.try(:partition_id),
                  partition_key: partition_key
                )
              end
            end
        end

        protected

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
