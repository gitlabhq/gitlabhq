# frozen_string_literal: true

module Organizations
  module Users
    class TransferService
      include Gitlab::Utils::StrongMemoize

      TransferError = Class.new(StandardError)
      BATCH_SIZE = 50

      def initialize(group:, new_organization:, current_user:)
        @group = group
        @new_organization = new_organization
        @current_user = current_user
      end

      def execute
        check_initial_transaction_state!

        return ServiceResponse.error(message: can_transfer_error) unless can_transfer?

        User.transaction do
          users.each_batch(of: BATCH_SIZE) do |user_batch|
            user_ids = user_batch.ids # rubocop:disable CodeReuse/ActiveRecord -- .ids is reasonable here
            next if user_ids.empty?

            update_users(user_ids)
            update_user_projects(user_ids)
          end
        end

        ServiceResponse.success
      rescue StandardError => e
        # Re-raise so outer transaction is also rolled back
        raise if called_within_transaction

        ServiceResponse.error(message: e.message)
      end

      # rubocop:disable CodeReuse/ActiveRecord -- Specific use for pluck
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- Not used in IN clause
      def can_transfer?
        organization_ids = users.pluck(:organization_id)

        return false unless organization_ids.any?

        organization_ids.all?(group.organization_id)
      end
      strong_memoize_attr :can_transfer?
      # rubocop:enable CodeReuse/ActiveRecord
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit

      def can_transfer_error
        return if can_transfer?

        s_("TransferOrganization|Cannot transfer users to a different organization " \
          "if all users do not belong to the same organization as the top-level group.")
      end

      private

      attr_reader :group, :new_organization, :current_user
      attr_accessor :called_within_transaction

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
      # rubocop:enable CodeReuse/ActiveRecord

      def transfer_attributes
        {
          organization_id: new_organization.id,
          visibility_level: Arel.sql('LEAST(?, visibility_level)', new_organization.visibility_level)
        }
      end

      def users
        group.users_with_descendants
      end

      def user_namespaces(user_ids)
        Namespaces::UserNamespace.for_owner(user_ids)
      end

      def check_initial_transaction_state!
        self.called_within_transaction = ::User.connection.transaction_open?
      end
    end
  end
end
