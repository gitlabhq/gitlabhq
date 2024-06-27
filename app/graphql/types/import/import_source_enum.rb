# frozen_string_literal: true

module Types
  module Import
    class ImportSourceEnum < BaseEnum
      graphql_name 'ImportSource'
      description 'Import source'
      class << self
        private

        def import_source_description(import_source)
          return "Not imported" if import_source == :none

          import_source.to_s.titleize
        end
      end

      ::Import::HasImportSource::IMPORT_SOURCES.each_key do |import_source|
        value import_source.upcase, value: import_source.to_s, description: import_source_description(import_source)
      end
    end
  end
end
