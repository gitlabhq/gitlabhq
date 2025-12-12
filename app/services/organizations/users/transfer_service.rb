# frozen_string_literal: true

module Organizations
  module Users
    class TransferService
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 50

      def initialize(users:, new_organization:)
        @users = users
        @new_organization = new_organization
      end

      def execute
        return ServiceResponse.error(message: transfer_error) unless can_transfer_users?

        # Only create a transaction if we're not already in one
        # This allows the related organization group transfer
        # service to manage the outer transaction
        in_outer_transaction = User.connection.transaction_open?

        if in_outer_transaction
          perform_transfer
        else
          User.transaction do
            perform_transfer
          end
        end

        ServiceResponse.success
      rescue StandardError => e
        # When in outer transaction: re-raise to propagate and trigger rollback
        # When managing own transaction: return error (transaction already rolled back)
        raise e if in_outer_transaction

        ServiceResponse.error(message: e.message)
      end

      # Pre-create bot users before the transaction to avoid exclusive lease errors
      # This is called by the group transfer service before starting the transaction
      def prepare_bots
        new_organization_bots
      end

      def can_transfer_users?
        return false unless users_belong_to_single_organization?
        return false unless old_organization.present?

        true
      end

      def transfer_error
        return organization_not_found_error unless old_organization.present?

        users_different_organizations_error unless users_belong_to_single_organization?
      end

      # rubocop:disable CodeReuse/ActiveRecord -- Query specific to this service
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- Using batches of 50
      def users_belong_to_single_organization?
        organization_ids = users.distinct.pluck(:organization_id).compact

        # All users must belong to exactly one organization
        organization_ids.size == 1
      end
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit
      # rubocop:enable CodeReuse/ActiveRecord

      private

      attr_reader :users, :new_organization

      def perform_transfer
        users.each_batch(of: BATCH_SIZE) do |user_batch|
          user_ids = user_batch.ids # rubocop:disable CodeReuse/ActiveRecord -- .ids is reasonable here
          next if user_ids.empty?

          update_users(user_ids)
          update_user_projects(user_ids)
          update_todos(user_ids)
        end
      end

      def update_users(user_ids)
        User.id_in(user_ids).update_all(organization_id: new_organization.id)
        user_namespaces(user_ids).update_all(transfer_attributes)
      end

      # rubocop:disable CodeReuse/ActiveRecord -- Only for .ids and .pluck which are reasonable uses
      def update_user_projects(user_ids)
        user_namespace_batch_ids = user_namespaces(user_ids).ids
        projects_scope = Project.in_namespace(user_namespace_batch_ids)

        projects_scope.each_batch(of: BATCH_SIZE) do |project_batch|
          project_ids = project_batch.ids
          next if project_ids.empty?

          # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- Using batches of 50
          project_namespace_ids = project_batch.pluck(:project_namespace_id)
          # rubocop:enable Database/AvoidUsingPluckWithoutLimit

          Namespaces::ProjectNamespace.where(id: project_namespace_ids).update_all(transfer_attributes)
          Project.id_in(project_ids).update_all(transfer_attributes)
        end
      end

      def update_todos(user_ids)
        old_organization_bots.each do |user_type, old_bot|
          new_bot = new_organization_bots[user_type]

          Todo.for_author(old_bot&.id).for_user(user_ids).update_all(author_id: new_bot.id)
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def new_organization_bots
        # rubocop:disable GitlabSecurity/PublicSend -- Safe usage
        old_organization_bots.keys.index_with do |user_type|
          ::Users::Internal.for_organization(new_organization).public_send(user_type.to_sym)
        end
        # rubocop:enable GitlabSecurity/PublicSend
      end
      strong_memoize_attr :new_organization_bots

      def old_organization
        # This is safe because can_transfer_users? ensures all users belong to the same organization
        users.pick(:organization_id).then { |id| Organizations::Organization.find_by_id(id) }
      end
      strong_memoize_attr :old_organization

      # These are organization-specific bots that may be the author of Todos.
      def old_organization_bots
        bot_types =
          %w[ghost support_bot alert_bot security_bot automation_bot duo_code_review_bot admin_bot]

        bot_types.index_with do |user_type|
          User.with_user_types(user_type).in_organization(old_organization).first
        end.compact
      end
      strong_memoize_attr :old_organization_bots

      def transfer_attributes
        {
          organization_id: new_organization.id,
          visibility_level: Arel.sql('LEAST(?, visibility_level)', new_organization.visibility_level)
        }
      end

      def user_namespaces(user_ids)
        Namespaces::UserNamespace.for_owner(user_ids)
      end

      def organization_not_found_error
        s_("TransferOrganization|Cannot transfer users because the existing organization could not be found.")
      end

      def users_different_organizations_error
        s_("TransferOrganization|Cannot transfer users to a different organization " \
          "if all users do not belong to the same organization as the top-level group.")
      end
    end
  end
end
