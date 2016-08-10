class DestroyGroupService
  attr_accessor :group, :current_user

  def initialize(group, user)
    @group, @current_user = group, user
  end

  def execute
    group.projects.each do |project|
      # Skip repository removal because we remove directory with namespace
      # that contain all this repositories
      ::Projects::DestroyService.new(project, current_user, skip_repo: true).async_execute
    end

    group.destroy
  end
end
