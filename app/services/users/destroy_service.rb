module Users
  class DestroyService
    attr_accessor :current_user

    def initialize(current_user)
      @current_user = current_user
    end

    # Synchronously destroys +user+
    #
    # The operation will fail if the user is the sole owner of any groups. To
    # force the groups to be destroyed, pass `delete_solo_owned_groups: true` in
    # +options+.
    #
    # The user's contributions will be migrated to a global ghost user. To
    # force the contributions to be destroyed, pass `hard_delete: true` in
    # +options+.
    #
    # `hard_delete: true` implies `delete_solo_owned_groups: true`.  To perform
    # a hard deletion without destroying solo-owned groups, pass
    # `delete_solo_owned_groups: false, hard_delete: true` in +options+.
    def execute(user, options = {})
      delete_solo_owned_groups = options.fetch(:delete_solo_owned_groups, options[:hard_delete])

      unless Ability.allowed?(current_user, :destroy_user, user)
        raise Gitlab::Access::AccessDeniedError, "#{current_user} tried to destroy user #{user}!"
      end

      if !delete_solo_owned_groups && user.solo_owned_groups.present?
        user.errors[:base] << 'You must transfer ownership or delete groups before you can remove user'
        return user
      end

      user.solo_owned_groups.each do |group|
        Groups::DestroyService.new(group, current_user).execute
      end

      namespace = user.namespace
      namespace.prepare_for_destroy

      user.personal_projects.each do |project|
        # Skip repository removal because we remove directory with namespace
        # that contain all this repositories
        ::Projects::DestroyService.new(project, current_user, skip_repo: project.legacy_storage?).execute
      end

      Project.includes(group: :owners).where(mirror_user: user).find_each do |project|
        if project.group.present?
          project.update(mirror_user: project.group.owners.first)
        end
      end

      MigrateToGhostUserService.new(user).execute unless options[:hard_delete]

      # Destroy the namespace after destroying the user since certain methods may depend on the namespace existing
      user_data = user.destroy
      namespace.really_destroy!

      user_data
    end
  end
end
