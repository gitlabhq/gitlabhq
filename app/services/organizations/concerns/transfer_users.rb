# frozen_string_literal: true

module Organizations
  module Concerns
    module TransferUsers
      BATCH_SIZE = 50

      private

      def transfer_users
        users.each_batch(of: BATCH_SIZE) do |user_batch|
          user_ids = user_batch.ids # rubocop:disable CodeReuse/ActiveRecord -- .ids is reasonable here
          next if user_ids.empty?

          update_users(user_ids)
          update_user_projects(user_ids)
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
      # rubocop:enable CodeReuse/ActiveRecord

      def transfer_attributes
        {
          organization_id: new_organization.id,
          visibility_level: Arel.sql('LEAST(?, visibility_level)', new_organization.visibility_level)
        }
      end

      def user_namespaces(user_ids)
        Namespaces::UserNamespace.for_owner(user_ids)
      end
    end
  end
end
