# frozen_string_literal: true

module API
  class FeatureFlagScopes < ::API::Base
    include PaginationParams

    ENVIRONMENT_SCOPE_ENDPOINT_REQUIREMENTS = FeatureFlags::FEATURE_FLAG_ENDPOINT_REQUIREMENTS
      .merge(environment_scope: API::NO_SLASH_URL_PART_REGEX)

    feature_category :feature_flags

    before do
      authorize_read_feature_flags!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :feature_flag_scopes do
        desc 'Get all effective feature flags under the environment' do
          detail 'This feature was introduced in GitLab 12.5'
          success ::API::Entities::FeatureFlag::DetailedLegacyScope
        end
        params do
          requires :environment, type: String, desc: 'The environment name'
        end
        get do
          present scopes_for_environment, with: ::API::Entities::FeatureFlag::DetailedLegacyScope
        end
      end

      params do
        requires :name, type: String, desc: 'The name of the feature flag'
      end
      resource 'feature_flags/:name', requirements: FeatureFlags::FEATURE_FLAG_ENDPOINT_REQUIREMENTS do
        resource :scopes do
          desc 'Get all scopes of a feature flag' do
            detail 'This feature was introduced in GitLab 12.5'
            success ::API::Entities::FeatureFlag::LegacyScope
          end
          params do
            use :pagination
          end
          get do
            present paginate(feature_flag.scopes), with: ::API::Entities::FeatureFlag::LegacyScope
          end

          desc 'Create a scope of a feature flag' do
            detail 'This feature was introduced in GitLab 12.5'
            success ::API::Entities::FeatureFlag::LegacyScope
          end
          params do
            requires :environment_scope, type: String, desc: 'The environment scope of the scope'
            requires :active, type: Boolean, desc: 'Whether the scope is active'
            requires :strategies, type: JSON, desc: 'The strategies of the scope'
          end
          post do
            authorize_update_feature_flag!

            result = ::FeatureFlags::UpdateService
              .new(user_project, current_user, scopes_attributes: [declared_params])
              .execute(feature_flag)

            if result[:status] == :success
              present scope, with: ::API::Entities::FeatureFlag::LegacyScope
            else
              render_api_error!(result[:message], result[:http_status])
            end
          end

          params do
            requires :environment_scope, type: String, desc: 'URL-encoded environment scope'
          end
          resource ':environment_scope', requirements: ENVIRONMENT_SCOPE_ENDPOINT_REQUIREMENTS do
            desc 'Get a scope of a feature flag' do
              detail 'This feature was introduced in GitLab 12.5'
              success ::API::Entities::FeatureFlag::LegacyScope
            end
            get do
              present scope, with: ::API::Entities::FeatureFlag::LegacyScope
            end

            desc 'Update a scope of a feature flag' do
              detail 'This feature was introduced in GitLab 12.5'
              success ::API::Entities::FeatureFlag::LegacyScope
            end
            params do
              optional :active, type: Boolean, desc: 'Whether the scope is active'
              optional :strategies, type: JSON, desc: 'The strategies of the scope'
            end
            put do
              authorize_update_feature_flag!

              scope_attributes = declared_params.merge(id: scope.id)

              result = ::FeatureFlags::UpdateService
                .new(user_project, current_user, scopes_attributes: [scope_attributes])
                .execute(feature_flag)

              if result[:status] == :success
                updated_scope = result[:feature_flag].scopes
                  .find { |scope| scope.environment_scope == params[:environment_scope] }

                present updated_scope, with: ::API::Entities::FeatureFlag::LegacyScope
              else
                render_api_error!(result[:message], result[:http_status])
              end
            end

            desc 'Delete a scope from a feature flag' do
              detail 'This feature was introduced in GitLab 12.5'
              success ::API::Entities::FeatureFlag::LegacyScope
            end
            delete do
              authorize_update_feature_flag!

              param = { scopes_attributes: [{ id: scope.id, _destroy: true }] }

              result = ::FeatureFlags::UpdateService
                .new(user_project, current_user, param)
                .execute(feature_flag)

              if result[:status] == :success
                status :no_content
              else
                render_api_error!(result[:message], result[:http_status])
              end
            end
          end
        end
      end
    end

    helpers do
      def authorize_read_feature_flags!
        authorize! :read_feature_flag, user_project
      end

      def authorize_update_feature_flag!
        authorize! :update_feature_flag, feature_flag
      end

      def feature_flag
        @feature_flag ||= user_project.operations_feature_flags
                                      .find_by_name!(params[:name])
      end

      def scope
        @scope ||= feature_flag.scopes
          .find_by_environment_scope!(CGI.unescape(params[:environment_scope]))
      end

      def scopes_for_environment
        Operations::FeatureFlagScope
          .for_unleash_client(user_project, params[:environment])
      end
    end
  end
end
