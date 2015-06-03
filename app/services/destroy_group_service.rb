class DestroyGroupService
  attr_accessor :group, :current_user

  def initialize(group, user)
    @group, @current_user = group, user
  end

  def execute
    @group.destroy
  end
end
