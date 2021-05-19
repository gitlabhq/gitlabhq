# frozen_string_literal: true

module ProtectedBranches
  class ApiService < BaseService
    def create
      ::ProtectedBranches::CreateService.new(@project, @current_user, protected_branch_params).execute
    end

    def protected_branch_params
      {
        name: params[:name],
        allow_force_push: allow_force_push?,
        push_access_levels_attributes: AccessLevelParams.new(:push, params).access_levels,
        merge_access_levels_attributes: AccessLevelParams.new(:merge, params).access_levels
      }
    end

    def allow_force_push?
      params[:allow_force_push] || false
    end
  end
end

ProtectedBranches::ApiService.prepend_mod_with('ProtectedBranches::ApiService')
