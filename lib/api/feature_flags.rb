# frozen_string_literal: true

module API
  class FeatureFlags < ::API::Base
    include PaginationParams

    FEATURE_FLAG_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
        .merge(name: API::NO_SLASH_URL_PART_REGEX)

    feature_category :feature_flags

    before do
      authorize_read_feature_flags!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :feature_flags do
        desc 'Get all feature flags of a project' do
          detail 'This feature was introduced in GitLab 12.5'
          success ::API::Entities::FeatureFlag
        end
        params do
          optional :scope, type: String, desc: 'The scope of feature flags',
                                         values: %w[enabled disabled]
          use :pagination
        end
        get do
          feature_flags = ::FeatureFlagsFinder
            .new(user_project, current_user, declared_params(include_missing: false))
            .execute

          present_entity(paginate(feature_flags))
        end

        desc 'Create a new feature flag' do
          detail 'This feature was introduced in GitLab 12.5'
          success ::API::Entities::FeatureFlag
        end
        params do
          requires :name, type: String, desc: 'The name of feature flag'
          optional :description, type: String, desc: 'The description of the feature flag'
          optional :active, type: Boolean, desc: 'Active/inactive value of the flag'
          optional :version, type: String, desc: 'The version of the feature flag'
          optional :scopes, type: Array do
            requires :environment_scope, type: String, desc: 'The environment scope of the scope'
            requires :active, type: Boolean, desc: 'Active/inactive of the scope'
            requires :strategies, type: JSON, desc: 'The strategies of the scope'
          end
          optional :strategies, type: Array do
            requires :name, type: String, desc: 'The strategy name'
            requires :parameters, type: JSON, desc: 'The strategy parameters'
            optional :scopes, type: Array do
              requires :environment_scope, type: String, desc: 'The environment scope of the scope'
            end
          end
        end
        post do
          authorize_create_feature_flag!

          attrs = declared_params(include_missing: false)

          rename_key(attrs, :scopes, :scopes_attributes)
          rename_key(attrs, :strategies, :strategies_attributes)
          update_value(attrs, :strategies_attributes) do |strategies|
            strategies.map { |s| rename_key(s, :scopes, :scopes_attributes) }
          end

          result = ::FeatureFlags::CreateService
            .new(user_project, current_user, attrs)
            .execute

          if result[:status] == :success
            present_entity(result[:feature_flag])
          else
            render_api_error!(result[:message], result[:http_status])
          end
        end
      end

      params do
        requires :feature_flag_name, type: String, desc: 'The name of the feature flag'
      end
      resource 'feature_flags/:feature_flag_name', requirements: FEATURE_FLAG_ENDPOINT_REQUIREMENTS do
        desc 'Get a feature flag of a project' do
          detail 'This feature was introduced in GitLab 12.5'
          success ::API::Entities::FeatureFlag
        end
        get do
          authorize_read_feature_flag!
          exclude_legacy_flags_check!

          present_entity(feature_flag)
        end

        desc 'Update a feature flag' do
          detail 'This feature was introduced in GitLab 13.2'
          success ::API::Entities::FeatureFlag
        end
        params do
          optional :name, type: String, desc: 'The name of the feature flag'
          optional :description, type: String, desc: 'The description of the feature flag'
          optional :active, type: Boolean, desc: 'Active/inactive value of the flag'
          optional :strategies, type: Array do
            optional :id, type: Integer, desc: 'The strategy id'
            optional :name, type: String, desc: 'The strategy type'
            optional :parameters, type: JSON, desc: 'The strategy parameters'
            optional :_destroy, type: Boolean, desc: 'Delete the strategy when true'
            optional :scopes, type: Array do
              optional :id, type: Integer, desc: 'The environment scope id'
              optional :environment_scope, type: String, desc: 'The environment scope of the scope'
              optional :_destroy, type: Boolean, desc: 'Delete the scope when true'
            end
          end
        end
        put do
          authorize_update_feature_flag!
          exclude_legacy_flags_check!
          render_api_error!('PUT operations are not supported for legacy feature flags', :unprocessable_entity) if feature_flag.legacy_flag?

          attrs = declared_params(include_missing: false)

          rename_key(attrs, :strategies, :strategies_attributes)
          update_value(attrs, :strategies_attributes) do |strategies|
            strategies.map { |s| rename_key(s, :scopes, :scopes_attributes) }
          end

          result = ::FeatureFlags::UpdateService
            .new(user_project, current_user, attrs)
            .execute(feature_flag)

          if result[:status] == :success
            present_entity(result[:feature_flag])
          else
            render_api_error!(result[:message], result[:http_status])
          end
        end

        desc 'Delete a feature flag' do
          detail 'This feature was introduced in GitLab 12.5'
          success ::API::Entities::FeatureFlag
        end
        delete do
          authorize_destroy_feature_flag!

          result = ::FeatureFlags::DestroyService
            .new(user_project, current_user, declared_params(include_missing: false))
            .execute(feature_flag)

          if result[:status] == :success
            present_entity(result[:feature_flag])
          else
            render_api_error!(result[:message], result[:http_status])
          end
        end
      end
    end

    helpers do
      def authorize_read_feature_flags!
        authorize! :read_feature_flag, user_project
      end

      def authorize_read_feature_flag!
        authorize! :read_feature_flag, feature_flag
      end

      def authorize_create_feature_flag!
        authorize! :create_feature_flag, user_project
      end

      def authorize_update_feature_flag!
        authorize! :update_feature_flag, feature_flag
      end

      def authorize_destroy_feature_flag!
        authorize! :destroy_feature_flag, feature_flag
      end

      def present_entity(result)
        present result,
          with: ::API::Entities::FeatureFlag
      end

      def feature_flag
        @feature_flag ||= user_project.operations_feature_flags.find_by_name!(params[:feature_flag_name])
      end

      def project
        @project ||= feature_flag.project
      end

      def new_version_flag_present?
        user_project.operations_feature_flags.new_version_flag.find_by_name(params[:name]).present?
      end

      def rename_key(hash, old_key, new_key)
        hash[new_key] = hash.delete(old_key) if hash.key?(old_key)
        hash
      end

      def update_value(hash, key)
        hash[key] = yield(hash[key]) if hash.key?(key)
        hash
      end

      def exclude_legacy_flags_check!
        if feature_flag.legacy_flag?
          not_found!
        end
      end
    end
  end
end
