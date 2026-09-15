# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module ProgrammingLanguagesImporter
      class << self
        def import
          definitions = normalize_definitions(load_definitions)
          definitions = reject_conflicts_and_unchanged(definitions)
          return if definitions.empty?

          ProgrammingLanguage.upsert_all(
            definitions,
            unique_by: :index_programming_languages_on_language_id,
            update_only: [:name, :color],
            record_timestamps: true
          )
        end

        private

        def load_definitions
          YAML.safe_load_file(Rails.root.join('vendor/languages.yml'))
        end

        def normalize_definitions(definitions)
          definitions.filter_map do |name, definition|
            next unless definition.is_a?(Hash)

            language_id = definition['language_id']
            color = definition['color']
            next if language_id.nil? || color.blank?

            { language_id: language_id, name: name, color: color }
          end
        end

        def reject_conflicts_and_unchanged(definitions)
          languages = ProgrammingLanguage.all.to_a
          languages_by_id = languages.index_by(&:language_id)
          languages_by_name = languages.index_by(&:name)

          definitions.reject do |definition|
            language_by_id = languages_by_id[definition[:language_id]]
            language_by_name = languages_by_name[definition[:name]]

            name_conflict = language_by_name && language_by_name != language_by_id
            unchanged = language_by_id &&
              language_by_id.name == definition[:name] &&
              language_by_id.color == definition[:color]

            name_conflict || unchanged
          end
        end
      end
    end
  end
end
