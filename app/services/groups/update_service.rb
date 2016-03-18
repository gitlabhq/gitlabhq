# Checks visibility level permission check before updating a group
# Do not allow to put Group visibility level smaller than its projects
# Do not allow unauthorized permission levels

module Groups
  class UpdateService < Groups::BaseService
    def execute
      group.assign_attributes(params)

      return false unless visibility_allowed_for_user?

      group.save
    end
  end
end
