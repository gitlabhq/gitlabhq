# frozen_string_literal: true

module Types
  module Organizations
    class VisibilityEnum < BaseEnum
      graphql_name 'OrganizationVisibility'
      description 'Visibilities available to an organization.'

      # rubocop:disable Graphql/EnumValues -- lowercased to match Types::VisibilityLevelsEnum
      value 'private', description: 'Private visibility.'
      value 'public', description: 'Public visibility.'
      # rubocop:enable Graphql/EnumValues
    end
  end
end
