# frozen_string_literal: true

module Mutations
  module Assignable
    extend ActiveSupport::Concern

    included do
      argument :assignee_usernames,
               [GraphQL::STRING_TYPE],
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

      update_service_class.new(
        resource.project,
        current_user,
        assignee_ids: assignee_ids(resource, assignee_usernames, operation_mode)
      ).execute(resource)

      {
        resource.class.name.underscore.to_sym => resource,
        errors: errors_on_object(resource)
      }
    end

    private

    def assignee_ids(resource, usernames, mode)
      new = UsersFinder.new(current_user, username: usernames).execute.map(&:id)

      transform_list(mode, resource, new)
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
