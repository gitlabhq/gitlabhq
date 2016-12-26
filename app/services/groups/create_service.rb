module Groups
  class CreateService < Groups::BaseService
    def initialize(user, params = {})
      @current_user, @params = user, params.dup
    end

    def execute
      @group = Group.new(params)

      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        deny_visibility_level(@group)
        return @group
      end

      parent_id = params[:parent_id]

      if parent_id
        parent = Group.find(parent_id)

        unless can?(current_user, :admin_group, parent)
          @group.parent_id = nil
          @group.errors.add(:parent_id, 'manage access required to create subgroup')

          return @group
        end
      end

      @group.name ||= @group.path.dup
      @group.save
      @group.add_owner(current_user)
      @group
    end
  end
end
