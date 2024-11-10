# frozen_string_literal: true

module Mutations
  module Issues
    class SetCrmContacts < Base
      graphql_name 'IssueSetCrmContacts'

      argument :contact_ids,
        [::Types::GlobalIDType[::CustomerRelations::Contact]],
        required: true,
        description: 'Customer relations contact IDs to set. Replaces existing contacts by default.'

      argument :operation_mode,
        Types::MutationOperationModeEnum,
        required: false,
        description: 'Changes the operation mode. Defaults to REPLACE.'

      def resolve(project_path:, iid:, contact_ids:, operation_mode: Types::MutationOperationModeEnum.enum[:replace])
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless feature_enabled?(project)

        contact_ids = contact_ids.compact.map do |contact_id|
          unless contact_id.respond_to?(:model_id)
            raise Gitlab::Graphql::Errors::ArgumentError, "Contact #{contact_id} is invalid."
          end

          contact_id.model_id.to_i
        end

        attribute_name = case operation_mode
                         when Types::MutationOperationModeEnum.enum[:append]
                           :add_ids
                         when Types::MutationOperationModeEnum.enum[:remove]
                           :remove_ids
                         else
                           :replace_ids
                         end

        response = ::Issues::SetCrmContactsService.new(
          container: project,
          current_user: current_user,
          params: { attribute_name => contact_ids }
        ).execute(issue)

        {
          issue: issue,
          errors: response.errors
        }
      end

      private

      def feature_enabled?(project)
        project.group&.crm_enabled?
      end
    end
  end
end
