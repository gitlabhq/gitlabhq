module Groups
  class CreateService < Groups::BaseService
    def initialize(user, params = {})
      @current_user, @params = user, params.dup
    end

    def execute
      @group = Group.new(params)

      return @group unless visibility_allowed_for_user?

      @group.name = @group.path.dup unless @group.name
      @group.save
      @group.add_owner(current_user)
      @group
    end
  end
end
