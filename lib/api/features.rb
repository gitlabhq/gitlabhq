# frozen_string_literal: true

module API
  class Features < ::API::Base
    before { authenticated_as_admin! }

    features_tags = %w[features]
    feature_category :feature_flags
    urgency :low

    resource :features do
      desc 'List all feature flags' do
        detail 'Lists all feature flags for the instance.'
        success Entities::Feature
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        tags features_tags
      end
      route_setting :authorization, permissions: :read_feature, boundary_type: :instance, assignable_when: [:admin]
      get do
        features = Feature.all

        present features, with: Entities::Feature, current_user: current_user
      end

      desc 'List all feature flag definitions' do
        detail 'Lists all feature flag definitions.'
        success Entities::Feature::Definition
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        tags features_tags
      end
      route_setting :authorization, permissions: :read_feature, boundary_type: :instance, assignable_when: [:admin]
      get :definitions do
        definitions = ::Feature::Definition.definitions.values.map(&:to_h)

        present definitions, with: Entities::Feature::Definition, current_user: current_user
      end

      desc 'Create or update a feature flag' do
        detail "Creates or updates a feature flag value. If a feature with the given name doesn't exist yet, " \
          "the operation creates one. The value can be a boolean or an integer to indicate percentage of time."
        success Entities::Feature
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        tags features_tags
      end
      params do
        requires :name, type: String, desc: 'Name of the feature flag.'
        requires :value,
          types: [String, Integer],
          desc: 'Value to set for the feature flag. Use `true` or `false` to enable or disable it, or an integer for ' \
            'the percentage of time it should be enabled.'
        optional :key,
          type: String,
          values: %w[percentage_of_actors percentage_of_time],
          desc: 'Rollout strategy for a percentage `value`. Omit it to apply the percentage to time'
        optional :feature_group, type: String, desc: 'Name of the feature group.'
        optional :user, type: String, desc: 'GitLab username or a comma-separated list of usernames.'
        optional :group,
          type: String,
          desc: 'GitLab group path, for example `gitlab-org`, or a comma-separated list of group paths.'
        optional :namespace,
          type: String,
          desc: 'GitLab group or user namespace path, for example `john-doe`, or a comma-separated list of namespace ' \
            'paths. Introduced in GitLab 15.0.'
        optional :project,
          type: String,
          desc: 'Project path, for example `gitlab-org/gitlab-foss`, or a comma-separated list of project paths.'
        optional :organization,
          type: String,
          desc: 'Organization ID or path, for example `1` or `default`, or a comma-separated list of organization ' \
            'IDs or paths.'
        optional :repository,
          type: String,
          desc: 'Repository path, for example `gitlab-org/gitlab-test.git`, `gitlab-org/gitlab-test.wiki.git`, or ' \
            '`snippets/21.git`. Use commas to separate multiple repository paths.'
        optional :runner,
          type: String,
          desc: 'Runner ID or a comma-separated list of runner IDs.'
        optional :endpoint,
          type: String,
          desc: 'Caller ID identifying a code path, for example `GET /api/v4/projects/:id` or ' \
            '`ProjectsController#show`. Use a comma to separate multiple endpoint paths.'
        optional :force, type: Boolean, desc: 'If `true`, skips feature flag validation checks, such as a YAML ' \
                                          'definition.'

        mutually_exclusive :key, :feature_group
        mutually_exclusive :key, :user
        mutually_exclusive :key, :group
        mutually_exclusive :key, :namespace
        mutually_exclusive :key, :project
        mutually_exclusive :key, :organization
        mutually_exclusive :key, :repository
        mutually_exclusive :key, :runner
        mutually_exclusive :key, :endpoint
      end
      route_setting :authorization, permissions: :update_feature, boundary_type: :instance, assignable_when: [:admin]
      post ':name' do
        flag_params = declared_params(include_missing: false)
        response = ::Admin::SetFeatureFlagService
          .new(feature_flag_name: params[:name], params: flag_params)
          .execute

        if response.success?
          present response.payload[:feature_flag],
            with: Entities::Feature, current_user: current_user
        else
          bad_request!(response.message)
        end
      end

      desc 'Delete a feature' do
        detail 'Deletes a feature gate. Returns the same response if the feature gate does not exist.'
        success code: 204, message: 'Resource deleted'
        tags features_tags
      end
      params do
        requires :name, type: String, desc: 'Name of the feature flag.'
      end
      route_setting :authorization, permissions: :delete_feature, boundary_type: :instance, assignable_when: [:admin]
      delete ':name' do
        Feature.remove(params[:name])

        no_content!
      end
    end
  end
end

API::Features.prepend_mod_with('API::Features')
