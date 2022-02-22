# frozen_string_literal: true

module Resolvers
  class TopicsResolver < BaseResolver
    type Types::Projects::TopicType, null: true

    argument :search, GraphQL::Types::String,
             required: false,
             description: 'Search query for topic name.'

    def resolve(**args)
      if args[:search].present?
        ::Projects::Topic.search(args[:search]).order_by_non_private_projects_count
      else
        ::Projects::Topic.order_by_non_private_projects_count
      end
    end
  end
end
