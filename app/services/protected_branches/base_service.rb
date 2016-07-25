module ProtectedBranches
  class BaseService < ::BaseService
    def set_access_levels!
      set_merge_access_levels!
      set_push_access_levels!
    end

    protected

    def set_merge_access_levels!
      case params[:allowed_to_merge]
      when 'masters'
        @protected_branch.merge_access_level.masters!
      when 'developers'
        @protected_branch.merge_access_level.developers!
      end
    end

    def set_push_access_levels!
      case params[:allowed_to_push]
      when 'masters'
        @protected_branch.push_access_level.masters!
      when 'developers'
        @protected_branch.push_access_level.developers!
      when 'no_one'
        @protected_branch.push_access_level.no_one!
      end
    end
  end
end
