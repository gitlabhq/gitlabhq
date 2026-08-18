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
      route_setting :authorization, permissions: :read_feature, boundary_type: :instance
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
      route_setting :authorization, permissions: :read_feature, boundary_type: :instance
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
        requires :name, type: String, desc: 'The name of the feature flag'
        requires :value,
          types: [String, Integer],
          desc: '`true` or `false` to enable/disable, or an integer for percentage of time'
        optional :key, type: String, desc: '`percentage_of_actors` or `percentage_of_time` (default)'
        optional :feature_group, type: String, desc: 'A Feature group name'
        optional :user, type: String, desc: 'A GitLab username or comma-separated multiple usernames'
        optional :group,
          type: String,
          desc: "A GitLab group's path, for example `gitlab-org`, or comma-separated multiple group paths"
        optional :namespace,
          type: String,
          desc: "A GitLab group or user namespace's path, for example `john-doe`, or comma-separated " \
            "multiple namespace paths. Introduced in GitLab 15.0."
        optional :project,
          type: String,
          desc: "A projects path, for example `gitlab-org/gitlab-foss`, or comma-separated multiple project paths"
        optional :organization,
          type: String,
          desc: "An organization ID or path, for example `1` or `default`, or comma-separated multiple " \
            "organization IDs or paths"
        optional :repository,
          type: String,
          desc: "A repository path, for example `gitlab-org/gitlab-test.git`, `gitlab-org/gitlab-test.wiki.git`, " \
            "`snippets/21.git`, to name a few. Use comma to separate multiple repository paths"
        optional :runner,
          type: String,
          desc: "A runner ID, or comma-separated list of runner IDs"
        optional :endpoint,
          type: String,
          desc: "A caller_id identifying a code path, for example `GET /api/v4/projects/:id` or " \
            "`ProjectsController#show`. Use comma to separate multiple endpoint paths"
        optional :force, type: Boolean, desc: 'Skip feature flag validation checks, such as a YAML definition'

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
      route_setting :authorization, permissions: :update_feature, boundary_type: :instance
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
        requires :name, type: String, desc: 'The name of the feature flag'
      end
      route_setting :authorization, permissions: :delete_feature, boundary_type: :instance
      delete ':name' do
        Feature.remove(params[:name])

        no_content!
      end
    end
  end
end

API::Features.prepend_mod_with('API::Features')
