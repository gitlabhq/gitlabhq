# frozen_string_literal: true

module Types
  module WorkItems
    class NotesFilterTypeEnum < BaseEnum
      graphql_name 'NotesFilterType'
      description 'Work item notes collection type.'

      ::UserPreference::NOTES_FILTERS.each_pair do |key, value|
        value key.upcase,
          value: value,
          description: UserPreference.notes_filters.invert[::UserPreference::NOTES_FILTERS[key]]
      end

      def self.default_value
        ::UserPreference::NOTES_FILTERS[:all_notes]
      end
    end
  end
end
