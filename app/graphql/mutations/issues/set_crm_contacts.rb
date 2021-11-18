# frozen_string_literal: true

module Mutations
  module Issues
    class SetCrmContacts < Base
      graphql_name 'IssueSetCrmContacts'

      argument :crm_contact_ids,
               [::Types::GlobalIDType[::CustomerRelations::Contact]],
               required: true,
               description: 'Customer relations contact IDs to set. Replaces existing contacts by default.'

      argument :operation_mode,
               Types::MutationOperationModeEnum,
               required: false,
               description: 'Changes the operation mode. Defaults to REPLACE.'

      def resolve(project_path:, iid:, crm_contact_ids:, operation_mode: Types::MutationOperationModeEnum.enum[:replace])
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless Feature.enabled?(:customer_relations, project.group, default_enabled: :yaml)

        crm_contact_ids = crm_contact_ids.compact.map do |crm_contact_id|
          raise Gitlab::Graphql::Errors::ArgumentError, "Contact #{crm_contact_id} is invalid." unless crm_contact_id.respond_to?(:model_id)

          crm_contact_id.model_id.to_i
        end

        attribute_name = case operation_mode
                         when Types::MutationOperationModeEnum.enum[:append]
                           :add_crm_contact_ids
                         when Types::MutationOperationModeEnum.enum[:remove]
                           :remove_crm_contact_ids
                         else
                           :crm_contact_ids
                         end

        response = ::Issues::SetCrmContactsService.new(project: project, current_user: current_user, params: { attribute_name => crm_contact_ids })
          .execute(issue)

        {
          issue: issue,
          errors: response.errors
        }
      end
    end
  end
end
