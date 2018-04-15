module EE
  module ProtectedBranches
    module ApiService
      extend ::Gitlab::Utils::Override

      GroupsNotAccessibleError = Class.new(StandardError)
      UsersNotAccessibleError = Class.new(StandardError)

      override :create
      def create
        super
      rescue ::EE::ProtectedBranches::ApiService::GroupsNotAccessibleError,
             ::EE::ProtectedBranches::ApiService::UsersNotAccessibleError
        ::ProtectedBranch.new.tap do |protected_branch|
          message = 'Cannot add users or groups unless they have access to the project'
          protected_branch.errors.add(:base, message)
        end
      end

      private

      override :verify_params!
      def verify_params!
        raise GroupsNotAccessibleError.new unless groups_accessible?
        raise UsersNotAccessibleError.new unless users_accessible?
      end

      def groups_accessible?
        group_ids = @merge_params.group_ids + @push_params.group_ids + @unprotect_params.group_ids # rubocop:disable Gitlab/ModuleWithInstanceVariables
        allowed_groups = @project.invited_groups.where(id: group_ids) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        group_ids.count == allowed_groups.count
      end

      def users_accessible?
        user_ids = @merge_params.user_ids + @push_params.user_ids + @unprotect_params.user_ids # rubocop:disable Gitlab/ModuleWithInstanceVariables
        allowed_users = @project.team.users.where(id: user_ids) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        user_ids.count == allowed_users.count
      end
    end
  end
end
