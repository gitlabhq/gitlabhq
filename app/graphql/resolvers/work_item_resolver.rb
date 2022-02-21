# frozen_string_literal: true

module Resolvers
  class WorkItemResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorize :read_issue

    type Types::WorkItemType, null: true

    argument :id, ::Types::GlobalIDType[::WorkItem], required: true, description: 'Global ID of the work item.'

    def resolve(id:)
      work_item = authorized_find!(id: id)
      return unless Feature.enabled?(:work_items, work_item.project)

      work_item
    end

    private

    def find_object(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[::WorkItem].coerce_isolated_input(id)
      GitlabSchema.find_by_gid(id)
    end
  end
end
