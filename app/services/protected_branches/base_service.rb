module ProtectedBranches
  class BaseService < ::BaseService
    def set_access_levels!
      if params[:developers_can_push] == '0'
        @protected_branch.push_access_level.masters!
      elsif params[:developers_can_push] == '1'
        @protected_branch.push_access_level.developers!
      end

      if params[:developers_can_merge] == '0'
        @protected_branch.merge_access_level.masters!
      elsif params[:developers_can_merge] == '1'
        @protected_branch.merge_access_level.developers!
      end
    end
  end
end
