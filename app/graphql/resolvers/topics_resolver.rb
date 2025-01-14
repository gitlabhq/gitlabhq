# frozen_string_literal: true

module Resolvers
  class TopicsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::Projects::TopicType, null: true

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Search query for topic name.'

    argument :organization_id, Types::GlobalIDType[::Organizations::Organization],
      required: false,
      prepare: ->(global_id, _ctx) { global_id&.model_id },
      experiment: { milestone: '17.7' },
      description: 'Global ID of the organization.'

    def resolve(**args)
      organization = authorized_find!(id: args[:organization_id] || ::Current.organization_id)

      return organization_topics(organization.id) unless args[:search].present?

      organization_topics(organization.id).search(args[:search])
    end

    private

    def find_object(id:)
      ::Organizations::Organization.find_by_id(id)
    end

    def authorized_resource?(organization)
      Ability.allowed?(current_user, :read_organization, organization)
    end

    def organization_topics(organization_id)
      ::Projects::Topic.for_organization(organization_id).order_by_non_private_projects_count
    end
  end
end
