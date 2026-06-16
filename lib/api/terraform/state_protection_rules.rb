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

          desc 'Create a Terraform state protection rule for a project' do
            detail 'This feature was introduced in GitLab 19.1.'
            success Entities::Terraform::StateProtectionRule
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' },
              { code: 422, message: 'Unprocessable Entity' }
            ]
            tags %w[projects]
          end
          params do
            requires :state_name, type: String, limit: 255,
              desc: 'Terraform state name to protect. Maximum 255 characters. Must be unique per project.'
            requires :minimum_access_level_for_write, type: String,
              values: ::Terraform::StateProtectionRule.minimum_access_level_for_writes.keys,
              desc: 'Minimum GitLab access level required to write to the Terraform state. ' \
                "Valid values: #{::Terraform::StateProtectionRule.minimum_access_level_for_writes.keys.join(', ')}."
            optional :allowed_from, type: String,
              values: ::Terraform::StateProtectionRule.allowed_froms.keys,
              desc: 'Source restriction for write requests. Default: anywhere. ' \
                "Valid values: #{::Terraform::StateProtectionRule.allowed_froms.keys.join(', ')}."
          end
          route_setting :authorization, permissions: :create_terraform_state_protection_rule, boundary_type: :project
          post do
            authorize! :create_terraform_state_protection_rule, user_project

            response = ::Terraform::StateProtectionRules::CreateRuleService.new(
              project: user_project,
              current_user: current_user,
              params: declared_params(include_missing: false)
            ).execute

            render_api_error!({ error: response.message }, :unprocessable_entity) if response.error?

            present response.payload[:terraform_state_protection_rule],
              with: Entities::Terraform::StateProtectionRule
          end

          params do
            requires :terraform_state_protection_rule_id, type: Integer,
              desc: 'The ID of the Terraform state protection rule'
          end
          resource ':terraform_state_protection_rule_id' do
            desc 'Update a Terraform state protection rule for a project' do
              detail 'This feature was introduced in GitLab 19.0.'
              success Entities::Terraform::StateProtectionRule
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' },
                { code: 422, message: 'Unprocessable Entity' }
              ]
              tags %w[projects]
            end
            params do
              optional :state_name, type: String,
                desc: 'Terraform state name to protect.'
              optional :minimum_access_level_for_write, type: String,
                values: ::Terraform::StateProtectionRule.minimum_access_level_for_writes.keys,
                desc: 'If defined, sets the minimum GitLab access level required to write to the Terraform state.'
              optional :allowed_from, type: String,
                values: ::Terraform::StateProtectionRule.allowed_froms.keys,
                desc: 'If defined, write requests must be made from the specific source.'
            end
            route_setting :authorization, permissions: :update_terraform_state_protection_rule, boundary_type: :project
            patch do
              authorize! :update_terraform_state_protection_rule, user_project

              protection_rule = user_project.terraform_state_protection_rules
                .find(params[:terraform_state_protection_rule_id])

              response = ::Terraform::StateProtectionRules::UpdateRuleService.new(
                protection_rule,
                current_user: current_user,
                params: declared_params(include_missing: false)
              ).execute

              render_api_error!({ error: response.message }, :unprocessable_entity) if response.error?

              present response.payload[:terraform_state_protection_rule],
                with: Entities::Terraform::StateProtectionRule
            end
          end

          params do
            requires :terraform_state_protection_rule_id, type: Integer,
              desc: 'The ID of the Terraform state protection rule'
          end
          resource ':terraform_state_protection_rule_id' do
            desc 'Delete a Terraform state protection rule' do
              detail 'This feature was introduced in GitLab 19.0.'
              success code: 204, message: '204 No Content'
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 401, message: 'Unauthorized' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[projects]
            end
            route_setting :authorization, permissions: :delete_terraform_state_protection_rule, boundary_type: :project
            delete do
              authorize! :delete_terraform_state_protection_rule, user_project

              protection_rule = user_project.terraform_state_protection_rules
                .find(params[:terraform_state_protection_rule_id])

              destroy_conditionally!(protection_rule) do |protection_rule|
                response = ::Terraform::StateProtectionRules::DeleteRuleService.new(
                  protection_rule,
                  current_user: current_user
                ).execute

                render_api_error!({ error: response.message }, :bad_request) if response.error?
              end
            end
          end
        end
      end
    end
  end
end
