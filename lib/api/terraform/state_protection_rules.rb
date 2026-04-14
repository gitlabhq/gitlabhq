# frozen_string_literal: true

module API
  module Terraform
    class StateProtectionRules < ::API::Base
      feature_category :infrastructure_as_code

      after_validation do
        authenticate!
        not_found! if Feature.disabled?(:protected_terraform_states, user_project)
        authorize! :read_terraform_state, user_project
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        resource ':id/terraform/state_protection_rules' do
          desc 'List all Terraform state protection rules for a project' do
            detail 'Lists all Terraform state protection rules for a project. ' \
              'This feature was introduced in GitLab 18.11.'
            success Entities::Terraform::StateProtectionRule
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[projects]
            is_array true
          end
          route_setting :authorization, permissions: :read_terraform_state, boundary_type: :project
          get do
            present user_project.terraform_state_protection_rules,
              with: Entities::Terraform::StateProtectionRule
          end
        end
      end
    end
  end
end
