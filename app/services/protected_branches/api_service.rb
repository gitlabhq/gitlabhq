# frozen_string_literal: true

module ProtectedBranches
  class ApiService < ProtectedBranches::BaseService
    def create
      ::ProtectedBranches::CreateService.new(project_or_group, @current_user, protected_branch_params).execute
    end

    def update(protected_branch)
      ::ProtectedBranches::UpdateService.new(project_or_group, @current_user,
        protected_branch_params(with_defaults: false)).execute(protected_branch)
    end

    private

    def protected_branch_params(with_defaults: true)
      params.slice(*attributes).merge(
        {
          push_access_levels_attributes: access_level_attributes(:push, with_defaults),
          merge_access_levels_attributes: access_level_attributes(:merge, with_defaults)
        }
      )
    end

    def access_level_attributes(type, with_defaults)
      ::ProtectedRefs::AccessLevelParams.new(
        type,
        params,
        with_defaults: with_defaults
      ).access_levels
    end

    def attributes
      [:name, :allow_force_push]
    end
  end
end

ProtectedBranches::ApiService.prepend_mod
