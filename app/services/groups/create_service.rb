module Groups
  class CreateService < Groups::BaseService
    def initialize(user, params = {})
      @current_user, @params = user, params.dup
      @group = Group.new(@params)
    end

    def execute
      return @group unless visibility_allowed_for_user?(@params[:visibility_level])
      @group.name = @group.path.dup unless @group.name
      @group.save
      @group.add_owner(@current_user)
      @group
    end
  end
end
