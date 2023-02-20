# frozen_string_literal: true

module Mutations
  module Issues
    class BulkUpdate < BaseMutation
      graphql_name 'IssuesBulkUpdate'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      MAX_ISSUES = 100

      description 'Allows updating several properties for a set of issues. ' \
                  'Does nothing if the `bulk_update_issues_mutation` feature flag is disabled.'

      argument :parent_id, ::Types::GlobalIDType[::IssueParent],
        required: true,
        description: 'Global ID of the parent that the bulk update will be scoped to . ' \
                     'Example `IssueParentID` are `"gid://gitlab/Project/1"` and `"gid://gitlab/Group/1"`.'

      argument :ids, [::Types::GlobalIDType[::Issue]],
        required: true,
        description: 'Global ID array of the issues that will be updated. ' \
                     "IDs that the user can\'t update will be ignored. A max of #{MAX_ISSUES} can be provided."

      argument :assignee_ids, [::Types::GlobalIDType[::User]],
        required: false,
        description: 'Global ID array of the users that will be assigned to the given issues. ' \
                     'Existing assignees will be replaced with the ones on this list.'

      argument :milestone_id, ::Types::GlobalIDType[::Milestone],
        required: false,
        description: 'Global ID of the milestone that will be assigned to the issues.'

      field :updated_issue_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of issues that were successfully updated.'

      def ready?(**args)
        if Feature.disabled?(:bulk_update_issues_mutation)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, '`bulk_update_issues_mutation` feature flag is disabled.'
        end

        if args[:ids].size > MAX_ISSUES
          raise Gitlab::Graphql::Errors::ArgumentError,
                format(_('No more than %{max_issues} issues can be updated at the same time'), max_issues: MAX_ISSUES)
        end

        super
      end

      def resolve(ids:, parent_id:, **attributes)
        parent = find_parent!(parent_id)

        result = Issuable::BulkUpdateService.new(
          parent,
          current_user,
          prepared_params(attributes, ids)
        ).execute('issue')

        if result.success?
          { updated_issue_count: result.payload[:count], errors: [] }
        else
          { errors: result.errors }
        end
      end

      private

      def find_parent!(parent_id)
        parent = GitlabSchema.find_by_gid(parent_id).sync
        raise_resource_not_available_error! unless current_user.can?("read_#{parent.to_ability_name}", parent)

        parent
      end

      def prepared_params(attributes, ids)
        prepared = { issuable_ids: model_ids_from(ids).uniq }

        global_id_arguments.each do |argument|
          next unless attributes.key?(argument)

          prepared[argument] = model_ids_from(attributes[argument])
        end

        prepared.transform_keys(param_mappings)
      end

      def param_mappings
        {}
      end

      def global_id_arguments
        %i[assignee_ids milestone_id]
      end

      def model_ids_from(attributes)
        return if attributes.nil?
        return attributes.map(&:model_id) if attributes.is_a?(Array)

        attributes.model_id
      end
    end
  end
end

Mutations::Issues::BulkUpdate.prepend_mod
