#Checks visibility level permission check before updating a group
#Do not allow to put Group visibility level smaller than its projects
#Do not allow unauthorized permission levels

module Groups
  class UpdateService < Groups::BaseService
    def execute
      return false unless visibility_level_allowed?(params[:visibility_level])
      group.update_attributes(params)
    end

    private

    def visibility_level_allowed?(level)
      return true unless level.present?

      visibility_allowed_for_project?(level) && visibility_allowed_for_user?(level)
    end
  end
end
