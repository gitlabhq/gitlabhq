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
               description: 'The operation to perform. Defaults to REPLACE.'
    end

    def resolve(project_path:, iid:, assignee_usernames:, operation_mode: Types::MutationOperationModeEnum.enum[:replace])
      resource = authorized_find!(project_path: project_path, iid: iid)

      Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/issues/36098') if resource.is_a?(MergeRequest)

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

    def assignee_ids(resource, usernames, operation_mode)
      assignee_ids = []
      assignee_ids += resource.assignees.map(&:id) if Types::MutationOperationModeEnum.enum.values_at(:remove, :append).include?(operation_mode)
      user_ids = UsersFinder.new(current_user, username: usernames).execute.map(&:id)

      if operation_mode == Types::MutationOperationModeEnum.enum[:remove]
        assignee_ids -= user_ids
      else
        assignee_ids |= user_ids
      end

      assignee_ids
    end
  end
end
