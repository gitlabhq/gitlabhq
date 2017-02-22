module Users
  class DestroyService
    attr_accessor :current_user

    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user, options = {})
      unless current_user.admin? || current_user == user
        raise Gitlab::Access::AccessDeniedError, "#{current_user} tried to destroy user #{user}!"
      end

      if !options[:delete_solo_owned_groups] && user.solo_owned_groups.present?
        user.errors[:base] << 'You must transfer ownership or delete groups before you can remove user'
        return user
      end

      user.solo_owned_groups.each do |group|
        Groups::DestroyService.new(group, current_user).execute
      end

      user.personal_projects.each do |project|
        # Skip repository removal because we remove directory with namespace
        # that contain all this repositories
        ::Projects::DestroyService.new(project, current_user, skip_repo: true).async_execute
      end

      # Destroy the namespace after destroying the user since certain methods may depend on the namespace existing
      namespace = user.namespace
      user_data = user.destroy
      namespace.really_destroy!

      user_data
    end
  end
end
