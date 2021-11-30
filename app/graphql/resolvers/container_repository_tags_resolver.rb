# frozen_string_literal: true

module Resolvers
  class ContainerRepositoryTagsResolver < BaseResolver
    type Types::ContainerRepositoryTagType.connection_type, null: true

    argument :sort, Types::ContainerRepositoryTagsSortEnum,
        description: 'Sort tags by these criteria.',
        required: false,
        default_value: nil

    argument :name, GraphQL::Types::String,
        description: 'Search by tag name.',
        required: false,
        default_value: nil

    def resolve(sort:, **filters)
      result = tags

      if filters[:name]
        result = tags.filter do |tag|
          tag.name.include?(filters[:name])
        end
      end

      result = sort_tags(result, sort) if sort
      result
    end

    private

    def sort_tags(to_be_sorted, sort)
      raise StandardError unless Types::ContainerRepositoryTagsSortEnum.enum.include?(sort)

      sort_value, _, direction = sort.to_s.rpartition('_')

      sorted = to_be_sorted.sort_by(&sort_value.to_sym)
      return sorted.reverse if direction == 'desc'

      sorted
    end

    def tags
      object.tags
    rescue Faraday::Error
      raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, "Can't connect to the Container Registry. If this error persists, please review the troubleshooting documentation."
    end
  end
end
