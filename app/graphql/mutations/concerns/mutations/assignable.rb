# frozen_string_literal: true

module Mutations
  module Assignable
    extend ActiveSupport::Concern

    included do
      argument :assignee_usernames,
               [GraphQL::Types::String],
               required: true,
               description: 'The usernames to assign to the resource. Replaces existing assignees by default.'

      argument :operation_mode,
               Types::MutationOperationModeEnum,
               required: false,
               default_value: Types::MutationOperationModeEnum.default_mode,
               description: 'The operation to perform. Defaults to REPLACE.'
    end

    def resolve(project_path:, iid:, assignee_usernames:, operation_mode:)
      resource = authorized_find!(project_path: project_path, iid: iid)
      users = new_assignees(resource, assignee_usernames)

      assign!(resource, users, operation_mode)

      {
        resource.class.name.underscore.to_sym => resource,
        errors: errors_on_object(resource)
      }
    end

    private

    def assign!(resource, users, operation_mode)
      update_service_class.new(
        project: resource.project,
        current_user: current_user,
        params: { assignee_ids: assignee_ids(resource, users, operation_mode) }
      ).execute(resource)
    end

    def new_assignees(resource, usernames)
      UsersFinder.new(current_user, username: usernames).execute.to_a
    end

    def assignee_ids(resource, users, mode)
      transform_list(mode, resource, users.map(&:id))
    end

    def current_assignee_ids(resource)
      resource.assignees.map(&:id)
    end

    def transform_list(mode, resource, new_values)
      case mode
      when 'REPLACE' then new_values
      when 'APPEND' then current_assignee_ids(resource) | new_values
      when 'REMOVE' then current_assignee_ids(resource) - new_values
      end
    end
  end
end
