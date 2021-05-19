# frozen_string_literal: true

module Resolvers
  class ReleaseResolver < BaseResolver
    type Types::ReleaseType, null: true

    argument :tag_name, GraphQL::STRING_TYPE,
            required: true,
            description: 'The name of the tag associated to the release.'

    alias_method :project, :object

    def self.single
      self
    end

    def resolve(tag_name:)
      ReleasesFinder.new(
        project,
        current_user,
        { tag: tag_name }
      ).execute.first
    end
  end
end
