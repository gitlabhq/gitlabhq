class DeleteUserService
  attr_accessor :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  def execute(user)
    if user.solo_owned_groups.present?
      user.errors[:base] << 'You must transfer ownership or delete groups before you can remove user'
      user
    else
      user.personal_projects.each do |project|
        # Skip repository removal because we remove directory with namespace
        # that contain all this repositories
        ::Projects::DestroyService.new(project, current_user, skip_repo: true).pending_delete!
      end

      user.destroy
    end
  end
end
