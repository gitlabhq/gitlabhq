# frozen_string_literal: true

module API
  class Features < ::API::Base
    before { authenticated_as_admin! }

    features_tags = %w[features]

    feature_category :feature_flags
    urgency :low

    BadValueError = Class.new(StandardError)

    # TODO: remove these helpers with feature flag set_feature_flag_service
    helpers do
      def gate_value(params)
        case params[:value]
        when 'true'
          true
        when '0', 'false'
          false
        else
          raise BadValueError unless params[:value].match? /^\d+(\.\d+)?$/

          # https://github.com/jnunemaker/flipper/blob/master/lib/flipper/typecast.rb#L47
          if params[:value].to_s.include?('.')
            params[:value].to_f
          else
            params[:value].to_i
          end
        end
      end

      def gate_key(params)
        case params[:key]
        when 'percentage_of_actors'
          :percentage_of_actors
        else
          :percentage_of_time
        end
      end

      def gate_targets(params)
        Feature::Target.new(params).targets
      end

      def gate_specified?(params)
        Feature::Target.new(params).gate_specified?
      end
    end

    resource :features do
      desc 'List all features' do
        detail 'Get a list of all persisted features, with its gate values.'
        success Entities::Feature
        is_array true
        tags features_tags
      end
      get do
        features = Feature.all

        present features, with: Entities::Feature, current_user: current_user
      end

      desc 'List all feature definitions' do
        detail 'Get a list of all feature definitions.'
        success Entities::Feature::Definition
        is_array true
        tags features_tags
      end
      get :definitions do
        definitions = ::Feature::Definition.definitions.values.map(&:to_h)

        present definitions, with: Entities::Feature::Definition, current_user: current_user
      end

      desc 'Set or create a feature' do
        detail "Set a feature's gate value. If a feature with the given name doesn't exist yet, it's created. " \
               "The value can be a boolean, or an integer to indicate percentage of time."
        success Entities::Feature
        failure [
          { code: 400, message: 'Bad request' }
        ]
        tags features_tags
      end
      params do
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
        optional :repository,
          type: String,
          desc: "A repository path, for example `gitlab-org/gitlab-test.git`, `gitlab-org/gitlab-test.wiki.git`, " \
                "`snippets/21.git`, to name a few. Use comma to separate multiple repository paths"
        optional :force, type: Boolean, desc: 'Skip feature flag validation checks, such as a YAML definition'

        mutually_exclusive :key, :feature_group
        mutually_exclusive :key, :user
        mutually_exclusive :key, :group
        mutually_exclusive :key, :namespace
        mutually_exclusive :key, :project
        mutually_exclusive :key, :repository
      end
      post ':name' do
        if Feature.enabled?(:set_feature_flag_service)
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
        else
          validate_feature_flag_name!(params[:name]) unless params[:force]

          targets = gate_targets(params)
          value = gate_value(params)
          key = gate_key(params)

          case value
          when true
            if gate_specified?(params)
              targets.each { |target| Feature.enable(params[:name], target) }
            else
              Feature.enable(params[:name])
            end
          when false
            if gate_specified?(params)
              targets.each { |target| Feature.disable(params[:name], target) }
            else
              Feature.disable(params[:name])
            end
          else
            if key == :percentage_of_actors
              Feature.enable_percentage_of_actors(params[:name], value)
            else
              Feature.enable_percentage_of_time(params[:name], value)
            end
          end

          present Feature.get(params[:name]), # rubocop:disable Gitlab/AvoidFeatureGet
            with: Entities::Feature, current_user: current_user
        end
      rescue BadValueError
        bad_request!("Value must be boolean or numeric, got #{params[:value]}")
      rescue Feature::Target::UnknownTargetError => e
        bad_request!(e.message)
      end

      desc 'Delete a feature' do
        detail "Removes a feature gate. Response is equal when the gate exists, or doesn't."
        tags features_tags
      end
      delete ':name' do
        Feature.remove(params[:name])

        no_content!
      end
    end

    # TODO: remove this helper with feature flag set_feature_flag_service
    helpers do
      def validate_feature_flag_name!(name)
        # no-op
      end
    end
  end
end

API::Features.prepend_mod_with('API::Features')
