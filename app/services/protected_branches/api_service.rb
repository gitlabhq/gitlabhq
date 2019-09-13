# frozen_string_literal: true

module ProtectedBranches
  class ApiService < BaseService
    def create
      ::ProtectedBranches::CreateService.new(@project, @current_user, protected_branch_params).execute
    end

    def protected_branch_params
      {
        name: params[:name],
        push_access_levels_attributes: AccessLevelParams.new(:push, params).access_levels,
        merge_access_levels_attributes: AccessLevelParams.new(:merge, params).access_levels
      }
    end
  end
end

ProtectedBranches::ApiService.prepend_if_ee('EE::ProtectedBranches::ApiService')
