module ProtectedBranches
  class ApiService < BaseService
    prepend EE::ProtectedBranches::ApiService

    def create
      @push_params = AccessLevelParams.new(:push, params)
      @merge_params = AccessLevelParams.new(:merge, params)
      @unprotect_params = AccessLevelParams.new(:unprotect, params)

      verify_params!

      protected_branch_params = {
        name: params[:name],
        push_access_levels_attributes: @push_params.access_levels,
        merge_access_levels_attributes: @merge_params.access_levels,
        unprotect_access_levels_attributes: @unprotect_params.access_levels
      }

      ::ProtectedBranches::CreateService.new(@project, @current_user, protected_branch_params).execute
    end

    private

    def verify_params!
      # EE-only
    end
  end
end
