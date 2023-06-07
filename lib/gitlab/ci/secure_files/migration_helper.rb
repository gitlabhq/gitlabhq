# frozen_string_literal: true

module Gitlab
  module Ci
    module SecureFiles
      class MigrationHelper
        class << self
          def migrate_to_remote_storage(&block)
            migrate_in_batches(
              ::Ci::SecureFile.with_files_stored_locally,
              ::Ci::SecureFileUploader::Store::REMOTE,
              &block
            )
          end

          private

          def batch_size
            ENV.fetch('MIGRATION_BATCH_SIZE', 10).to_i
          end

          def migrate_in_batches(files, store, &block)
            files.find_each(batch_size: batch_size) do |file| # rubocop:disable CodeReuse/ActiveRecord
              file.file.migrate!(store)

              yield file if block
            end
          end
        end
      end
    end
  end
end
