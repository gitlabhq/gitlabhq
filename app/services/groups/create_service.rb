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

      # Repository size limit comes as MB from the view
      limit = params.delete(:repository_size_limit)
      @group.repository_size_limit = (limit.to_i.megabytes if limit.present?)

      if @group.parent && !can?(current_user, :admin_group, @group.parent)
        @group.parent = nil
        @group.errors.add(:parent_id, 'manage access required to create subgroup')

        return @group
      end

      @group.name ||= @group.path.dup
      @group.save
      @group.add_owner(current_user)
      @group
    end
  end
end
