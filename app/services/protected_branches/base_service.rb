module ProtectedBranches
  class BaseService < ::BaseService
    def initialize(project, current_user, params = {})
      super(project, current_user, params)
      @allowed_to_push = params[:allowed_to_push]
      @allowed_to_merge = params[:allowed_to_merge]
    end

    def set_access_levels!
      translate_api_params!
      set_merge_access_levels!
      set_push_access_levels!
    end

    private

    def set_merge_access_levels!
      case @allowed_to_merge
      when 'masters'
        @protected_branch.merge_access_level.masters!
      when 'developers'
        @protected_branch.merge_access_level.developers!
      end
    end

    def set_push_access_levels!
      case @allowed_to_push
      when 'masters'
        @protected_branch.push_access_level.masters!
      when 'developers'
        @protected_branch.push_access_level.developers!
      when 'no_one'
        @protected_branch.push_access_level.no_one!
      end
    end

    # The `branches` API still uses `developers_can_push` and `developers_can_merge`,
    # which need to be translated to `allowed_to_push` and `allowed_to_merge`,
    # respectively.
    def translate_api_params!
      @allowed_to_push ||=
        case to_boolean(params[:developers_can_push])
        when true
          'developers'
        when false
          'masters'
        end

      @allowed_to_merge ||=
        case to_boolean(params[:developers_can_merge])
        when true
          'developers'
        when false
          'masters'
        end
    end

    protected

    def to_boolean(value)
      return true if value =~ /^(true|t|yes|y|1|on)$/i
      return false if value =~ /^(false|f|no|n|0|off)$/i

      nil
    end
  end
end
