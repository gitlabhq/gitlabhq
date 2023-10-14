# frozen_string_literal: true

module RuboCop
  class BatchedBackgroundMigrations
    DICTIONARY_BASE_DIR = 'db/docs/batched_background_migrations'

    attr_reader :queued_migration_version

    class << self
      def dictionary_data
        @dictionary_data ||= Dir.glob("*.yml", base: DICTIONARY_BASE_DIR).each_with_object({}) do |file_name, data|
          dictionary = YAML.load_file(File.join(DICTIONARY_BASE_DIR, file_name))

          next unless dictionary['queued_migration_version'].present?

          data[dictionary['queued_migration_version'].to_s] = {
            finalize_after: dictionary['finalize_after'],
            finalized_by: dictionary['finalized_by'].to_s
          }
        end
      end
    end

    def initialize(queued_migration_version)
      @queued_migration_version = queued_migration_version
    end

    def finalized_by
      self.class.dictionary_data.dig(queued_migration_version.to_s, :finalized_by)
    end
  end
end
