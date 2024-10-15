# frozen_string_literal: true

module Gitlab
  module Utils
    class BatchedBackgroundMigrationsDictionary
      DICTIONARY_BASE_DIR = 'db/docs/batched_background_migrations'

      attr_reader :queued_migration_version

      class << self
        def entries
          return @entries if @entries.present? && defined?(Rails) && !Rails.env.test?

          @entries = Dir.glob("*.yml", base: DICTIONARY_BASE_DIR).each_with_object({}) do |file_name, data|
            dictionary = YAML.load_file(File.join(DICTIONARY_BASE_DIR, file_name))

            next unless dictionary['queued_migration_version'].present?

            data[dictionary['queued_migration_version'].to_s] = {
              migration_job_name: dictionary['migration_job_name'],
              introduced_by_url: dictionary['introduced_by_url'],
              finalized_by: dictionary['finalized_by'].to_s,
              milestone: dictionary['milestone']
            }

            data[dictionary['migration_job_name']] = data[dictionary['queued_migration_version'].to_s].merge(
              queued_migration_version: dictionary['queued_migration_version']
            )
          end
        end

        def entry(migration_job_name)
          return unless entries&.dig(migration_job_name)

          new(entries[migration_job_name][:queued_migration_version])
        end

        # Used by BackgroundMigration/DictionaryFile cop to invalidate its cache
        # if the contents of `db/docs/batched_background_migrations` changes.
        def checksum(skip_memoization: false)
          return @checksum if @checksum.present? && !skip_memoization

          @checksum = Digest::SHA256.hexdigest(entries.to_s)
        end
      end

      def initialize(queued_migration_version)
        @queued_migration_version = queued_migration_version
      end

      def finalized_by
        entry&.dig(:finalized_by)
      end

      def introduced_by_url
        entry&.dig(:introduced_by_url)
      end

      def milestone
        entry&.dig(:milestone)
      end

      def migration_job_name
        entry&.dig(:migration_job_name)
      end

      private

      def entry
        @entry ||= self.class.entries[queued_migration_version.to_s]
      end
    end
  end
end
