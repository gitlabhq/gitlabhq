module Groups
  class BaseService
    attr_accessor :group, :current_user, :params

    def initialize(group, user, params = {})
      @group, @current_user, @params = group, user, params.dup
    end

    private

    def visibility_allowed_for_user?
      level = group.visibility_level
      allowed_by_user  = Gitlab::VisibilityLevel.allowed_for?(current_user, level)

      group.errors.add(:visibility_level, "#{level} has been restricted by your GitLab administrator.") unless allowed_by_user
      
      allowed_by_user
    end
  end
end
