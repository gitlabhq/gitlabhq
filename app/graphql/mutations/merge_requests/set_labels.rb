# frozen_string_literal: true

module Mutations
  module MergeRequests
    class SetLabels < Base
      graphql_name 'MergeRequestSetLabels'

      argument :label_ids,
               [GraphQL::ID_TYPE],
               required: true,
               description: <<~DESC
                            The Label IDs to set. Replaces existing labels by default.
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

        label_ids = label_ids
                      .select(&method(:label_descendant?))
                      .map { |gid| GlobalID.parse(gid).model_id } # MergeRequests::UpdateService expects integers

        attribute_name = case operation_mode
                         when Types::MutationOperationModeEnum.enum[:append]
                           :add_label_ids
                         when Types::MutationOperationModeEnum.enum[:remove]
                           :remove_label_ids
                         else
                           :label_ids
                         end

        ::MergeRequests::UpdateService.new(project, current_user, attribute_name => label_ids)
          .execute(merge_request)

        {
          merge_request: merge_request,
          errors: merge_request.errors.full_messages
        }
      end

      def label_descendant?(gid)
        GlobalID.parse(gid)&.model_class&.ancestors&.include?(Label)
      end
    end
  end
end
