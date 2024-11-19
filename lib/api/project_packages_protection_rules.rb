# frozen_string_literal: true

module API
  class ProjectPackagesProtectionRules < ::API::Base
    feature_category :package_registry
    helpers ::API::Helpers::PackagesHelpers

    after_validation do
      authenticate!
      authorize_admin_package!
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource ':id/packages/protection/rules' do
        desc 'Get list of package protection rules for a project' do
          success Entities::Projects::Packages::Protection::Rule
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[projects]
          is_array true
        end
        get do
          present user_project.package_protection_rules, with: Entities::Projects::Packages::Protection::Rule
        end

        desc 'Create a package protection rule for a project' do
          success Entities::Projects::Packages::Protection::Rule
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
          requires :package_name_pattern, type: String,
            desc: 'Package name protected by the rule. For example @my-scope/my-package-*.
            Wildcard character * allowed.'
          requires :package_type, type: String, values: Packages::Protection::Rule.package_types.keys,
            desc: 'Package type protected by the rule. For example npm.'
          requires :minimum_access_level_for_push, type: String,
            values: Packages::Protection::Rule.minimum_access_level_for_pushes.keys,
            desc: 'Minimum GitLab access level able to push a package. Must be at least `maintainer`.
            For example `maintainer`, `owner` or `admin`.'
        end
        post do
          response = ::Packages::Protection::CreateRuleService.new(project: user_project, current_user: current_user,
            params: declared_params).execute

          render_api_error!({ error: response.message }, :unprocessable_entity) if response.error?

          present response[:package_protection_rule], with: Entities::Projects::Packages::Protection::Rule
        end

        params do
          requires :package_protection_rule_id, type: Integer, desc: 'The ID of the package protection rule'
        end
        resource ':package_protection_rule_id' do
          desc 'Update a package protection rule for a project' do
            success Entities::Projects::Packages::Protection::Rule
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
            optional :package_name_pattern, type: String,
              desc: 'Package name protected by the rule. For example @my-scope/my-package-*.
              Wildcard character * allowed.'
            optional :package_type, type: String, values: Packages::Protection::Rule.package_types.keys,
              desc: 'Package type protected by the rule. For example npm.'
            optional :minimum_access_level_for_push, type: String,
              values: Packages::Protection::Rule.minimum_access_level_for_pushes.keys,
              desc: 'Minimum GitLab access level able to push a package. Must be at least `maintainer`.
              For example `maintainer`, `owner` or `admin`.'
          end
          patch do
            package_protection_rule = user_project.package_protection_rules.find(params[:package_protection_rule_id])

            response = ::Packages::Protection::UpdateRuleService.new(package_protection_rule,
              current_user: current_user, params: declared_params(include_missing: false)).execute

            render_api_error!({ error: response.message }, :unprocessable_entity) if response.error?

            present response[:package_protection_rule], with: Entities::Projects::Packages::Protection::Rule
          end

          desc 'Delete package protection rule' do
            success code: 204, message: '204 No Content'
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[projects]
          end
          delete do
            package_protection_rule = user_project.package_protection_rules.find(params[:package_protection_rule_id])

            destroy_conditionally!(package_protection_rule) do |package_protection_rule|
              response = ::Packages::Protection::DeleteRuleService.new(package_protection_rule,
                current_user: current_user).execute

              render_api_error!({ error: response.message }, :bad_request) if response.error?
            end
          end
        end
      end
    end
  end
end
