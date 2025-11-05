# frozen_string_literal: true

module Organizations
  module Concerns
    module TransferUsers
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 50

      private

      def transfer_users
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
          Users::Internal.for_organization(new_organization).public_send(user_type.to_sym)
        end
        # rubocop:enable GitlabSecurity/PublicSend
      end
      strong_memoize_attr :new_organization_bots

      def old_organization_bots
        bot_types =
          %w[ghost support_bot alert_bot migration_bot security_bot automation_bot duo_code_review_bot admin_bot]

        bot_types.index_with do |user_type|
          User.with_user_types(user_type).in_organization(group.organization).first
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
    end
  end
end
