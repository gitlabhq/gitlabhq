# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class BatchedMigrationLastId
        FILE_NAME = 'last-batched-background-migration-id.txt'

        def initialize(connection, base_dir)
          @connection = connection
          @base_dir = base_dir
        end

        def store
          File.open(file_path, 'wb') { |file| file.write(last_background_migration_id) }
        end

        # Reads the last id from the file
        #
        # @info casts the file content into an +Integer+.
        #       Casts any unexpected content to +nil+
        #
        # @example
        #   Integer('4', exception: false) # => 4
        #   Integer('', exception: false) # => nil
        #
        # @return [Integer, nil]
        def read
          return unless File.exist?(file_path)

          Integer(File.read(file_path).presence, exception: false)
        end

        private

        attr_reader :connection, :base_dir

        def file_path
          @file_path ||= base_dir.join(FILE_NAME)
        end

        def last_background_migration_id
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::BackgroundMigration::BatchedMigration.maximum(:id)
          end
        end
      end
    end
  end
end
