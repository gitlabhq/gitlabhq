class DestroyGroupService
  attr_accessor :group, :current_user

  def initialize(group, user)
    @group, @current_user = group, user
  end

  def execute
    # TODO: Skip remove repository so Namespace#rm_dir works
    @group.projects.each do |project|
      ::Projects::DestroyService.new(project, current_user, {}).execute
    end

    @group.destroy
  end
end
