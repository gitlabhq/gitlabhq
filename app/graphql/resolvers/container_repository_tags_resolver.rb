# frozen_string_literal: true

module Resolvers
  class ContainerRepositoryTagsResolver < BaseResolver
    type Types::ContainerRegistry::ContainerRepositoryTagType.connection_type, null: true

    argument :sort, Types::ContainerRegistry::ContainerRepositoryTagsSortEnum,
      description: 'Sort tags by these criteria.',
      required: false,
      default_value: nil

    argument :name, GraphQL::Types::String,
      description: 'Search by tag name.',
      required: false,
      default_value: nil

    argument :referrers, GraphQL::Types::Boolean,
      description: 'Include tag referrers.',
      required: false,
      default_value: nil

    argument :referrer_type, GraphQL::Types::String,
      description: 'Comma-separated list of artifact types used to filter referrers. Applies only when `referrers` is set to `true`.',
      required: false,
      default_value: nil

    alias_method :container_repository, :object

    def resolve(sort:, **filters)
      if container_repository.gitlab_api_client.supports_gitlab_api?
        page_size = [filters[:first], filters[:last]].map(&:to_i).max

        result = container_repository.tags_page(
          before: filters[:before],
          last: filters[:after],
          sort: map_sort_field(sort),
          name: filters[:name],
          page_size: page_size,
          referrers: filters[:referrers],
          referrer_type: filters[:referrer_type]
        )

        Gitlab::Graphql::ExternallyPaginatedArray.new(
          parse_pagination_cursor(result, :previous),
          parse_pagination_cursor(result, :next),
          *result[:tags]
        )
      else
        result = tags

        if filters[:name]
          result = tags.filter do |tag|
            tag.name.include?(filters[:name])
          end
        end

        result = sort_tags(result, sort) if sort
        result
      end
    end

    private

    def parse_pagination_cursor(result, direction)
      pagination_uri = result.dig(:pagination, direction, :uri)

      return unless pagination_uri

      query_params =  CGI.parse(pagination_uri.query)
      key = direction == :previous ? 'before' : 'last'

      query_params[key]&.first
    end

    def map_sort_field(sort_value)
      return if sort_value.blank?

      sort = sort_value.to_s.gsub(/_(desc|asc)$/, '')
      sort = "-#{sort}" if sort_value.end_with?('_desc')

      sort
    end

    def sort_tags(to_be_sorted, sort)
      raise StandardError unless Types::ContainerRegistry::ContainerRepositoryTagsSortEnum.enum.include?(sort)

      sort_value, _, direction = sort.to_s.rpartition('_')

      sorted = to_be_sorted.sort_by(&sort_value.to_sym)
      return sorted.reverse if direction == 'desc'

      sorted
    end

    def tags
      container_repository.tags
    rescue Faraday::Error
      raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, "Can't connect to the Container Registry. If this error persists, please review the troubleshooting documentation."
    end
  end
end
