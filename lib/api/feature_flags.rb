# frozen_string_literal: true

module API
  class FeatureFlags < ::API::Base
    include PaginationParams

    feature_flags_tags = %w[feature_flags]

    FEATURE_FLAG_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
        .merge(name: API::NO_SLASH_URL_PART_REGEX)

    feature_category :feature_flags
    urgency :low

    before do
      authorize_read_feature_flags!
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :feature_flags do
        desc 'List feature flags for a project' do
          detail 'Gets all feature flags of the requested project. This feature was introduced in GitLab 12.5.'
          success ::API::Entities::FeatureFlag
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags feature_flags_tags
        end
        params do
          optional :scope,
            type: String,
            desc: 'The scope of feature flags, one of: `enabled`, `disabled`',
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
          detail 'Creates a new feature flag. This feature was introduced in GitLab 12.5.'
          success ::API::Entities::FeatureFlag
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' }
          ]
          tags feature_flags_tags
        end
        params do
          requires :name, type: String, desc: 'The name of the feature flag'
          optional :description, type: String, desc: 'The description of the feature flag'
          optional :active, type: Boolean, desc: 'The active state of the flag. Defaults to `true`. Supported in GitLab 13.3 and later'
          optional :version, type: String, desc: 'The version of the feature flag. Must be `new_version_flag`. Omit to create a Legacy feature flag.'
          optional :strategies, type: Array do
            requires :name, type: String, desc: 'The strategy name. Can be `default`, `gradualRolloutUserId`, `userWithId`, or `gitlabUserList`. In GitLab 13.5 and later, can be `flexibleRollout`'
            optional :parameters, type: JSON, desc: 'The strategy parameters as a JSON-formatted string e.g. `{"userIds":"user1"}`', documentation: { type: 'String' }
            optional :user_list_id, type: Integer, desc: "The ID of the feature flag user list. If strategy is `gitlabUserList`."
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
        desc 'Get a single feature flag' do
          detail 'Gets a single feature flag. This feature was introduced in GitLab 12.5.'
          success ::API::Entities::FeatureFlag
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags feature_flags_tags
        end
        get do
          authorize_read_feature_flag!
          exclude_legacy_flags_check!

          present_entity(feature_flag)
        end

        desc 'Update a feature flag' do
          detail 'Updates a feature flag. This feature was introduced in GitLab 13.2.'
          success ::API::Entities::FeatureFlag
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags feature_flags_tags
        end
        params do
          optional :name, type: String, desc: 'The new name of the feature flag. Supported in GitLab 13.3 and later'
          optional :description, type: String, desc: 'The description of the feature flag'
          optional :active, type: Boolean, desc: 'The active state of the flag. Supported in GitLab 13.3 and later'
          optional :strategies, type: Array do
            optional :id, type: Integer, desc: 'The feature flag strategy ID'
            optional :name, type: String, desc: 'The strategy name'
            optional :parameters, type: JSON, desc: 'The strategy parameters as a JSON-formatted string e.g. `{"userIds":"user1"}`', documentation: { type: 'String' }
            optional :user_list_id, type: Integer, desc: "The ID of the feature flag user list"
            optional :_destroy, type: Boolean, desc: 'Delete the strategy when true'
            optional :scopes, type: Array do
              optional :id, type: Integer, desc: 'The scope id'
              optional :environment_scope, type: String, desc: 'The environment scope of the scope'
              optional :_destroy, type: Boolean, desc: 'Delete the scope when true'
            end
          end
        end
        put do
          authorize_update_feature_flag!
          exclude_legacy_flags_check!
          render_api_error!('PUT operations are not supported for legacy feature flags', :unprocessable_entity) unless feature_flag.new_version_flag?

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
          detail 'Deletes a feature flag. This feature was introduced in GitLab 12.5.'
          success ::API::Entities::FeatureFlag
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags feature_flags_tags
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
        unless feature_flag.new_version_flag?
          not_found!
        end
      end
    end
  end
end
