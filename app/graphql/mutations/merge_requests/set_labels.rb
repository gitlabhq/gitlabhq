# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetLabels < Base
      graphql_name 'MergeRequestSetLabels'

      argument :label_ids,
        [::Types::GlobalIDType[Label]],
        required: true,
        description: <<~DESC
                 Label IDs to set. Replaces existing labels by default.
        DESC

      argument :operation_mode,
        Types::MutationOperationModeEnum,
        required: false,
        description: <<~DESC
                 Changes the operation mode. Defaults to REPLACE.
        DESC

      def resolve(project_path:, iid:, label_ids:, operation_mode: Types::MutationOperationModeEnum.enum[:replace])
        merge_request = authorized_find!(project_path: project_path, iid: iid)
        project = merge_request.project

        # MergeRequests::UpdateService expects integers
        label_ids = label_ids.compact.map(&:model_id)

        attribute_name = case operation_mode
                         when Types::MutationOperationModeEnum.enum[:append]
                           :add_label_ids
                         when Types::MutationOperationModeEnum.enum[:remove]
                           :remove_label_ids
                         else
                           :label_ids
                         end

        ::MergeRequests::UpdateService.new(
          project: project,
          current_user: current_user,
          params: { attribute_name => label_ids }
        ).execute(merge_request)

        {
          merge_request: merge_request,
          errors: errors_on_object(merge_request)
        }
      end
    end
  end
end
