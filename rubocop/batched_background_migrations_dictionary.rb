# frozen_string_literal: true

module RuboCop
  class BatchedBackgroundMigrationsDictionary
    DICTIONARY_BASE_DIR = 'db/docs/batched_background_migrations'

    attr_reader :queued_migration_version

    class << self
      def dictionary_data
        @dictionary_data ||= Dir.glob("*.yml", base: DICTIONARY_BASE_DIR).each_with_object({}) do |file_name, data|
          dictionary = YAML.load_file(File.join(DICTIONARY_BASE_DIR, file_name))

          next unless dictionary['queued_migration_version'].present?

          data[dictionary['queued_migration_version'].to_s] = {
            introduced_by_url: dictionary['introduced_by_url'],
            finalize_after: dictionary['finalize_after'],
            finalized_by: dictionary['finalized_by'].to_s,
            milestone: dictionary['milestone']
          }
        end
      end

      def checksum
        @checksum ||= Digest::SHA256.hexdigest(dictionary_data.to_s)
      end
    end

    def initialize(queued_migration_version)
      @queued_migration_version = queued_migration_version
    end

    def finalized_by
      dictionary_data&.dig(:finalized_by)
    end

    def finalize_after
      dictionary_data&.dig(:finalize_after)
    end

    def introduced_by_url
      dictionary_data&.dig(:introduced_by_url)
    end

    def milestone
      dictionary_data&.dig(:milestone)
    end

    private

    def dictionary_data
      @dictionary_data ||= self.class.dictionary_data[queued_migration_version.to_s]
    end
  end
end
