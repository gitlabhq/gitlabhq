# frozen_string_literal: true

module Gitlab
  module Terraform
    class StateMigrationHelper
      class << self
        def migrate_to_remote_storage(&block)
          migrate_in_batches(
            ::Terraform::StateVersion.with_files_stored_locally.preload_state,
            ::Terraform::StateUploader::Store::REMOTE,
            &block
          )
        end

        private

        def batch_size
          ENV.fetch('MIGRATION_BATCH_SIZE', 10).to_i
        end

        def migrate_in_batches(versions, store, &block)
          versions.find_each(batch_size: batch_size) do |version| # rubocop:disable CodeReuse/ActiveRecord
            version.file.migrate!(store)

            yield version if block
          end
        end
      end
    end
  end
end
