# frozen_string_literal: true

module API
  class Features < ::API::Base
    before { authenticated_as_admin! }

    feature_category :feature_flags

    helpers do
      def gate_value(params)
        case params[:value]
        when 'true'
          true
        when '0', 'false'
          false
        else
          params[:value].to_i
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
      desc 'Get a list of all features' do
        success Entities::Feature
      end
      get do
        features = Feature.all

        present features, with: Entities::Feature, current_user: current_user
      end

      desc 'Get a list of all feature definitions' do
        success Entities::Feature::Definition
      end
      get :definitions do
        definitions = ::Feature::Definition.definitions.values.map(&:to_h)

        present definitions, with: Entities::Feature::Definition, current_user: current_user
      end

      desc 'Set the gate value for the given feature' do
        success Entities::Feature
      end
      params do
        requires :value, type: String, desc: '`true` or `false` to enable/disable, an integer for percentage of time'
        optional :key, type: String, desc: '`percentage_of_actors` or the default `percentage_of_time`'
        optional :feature_group, type: String, desc: 'A Feature group name'
        optional :user, type: String, desc: 'A GitLab username'
        optional :group, type: String, desc: "A GitLab group's path, such as 'gitlab-org'"
        optional :project, type: String, desc: 'A projects path, like gitlab-org/gitlab-ce'
        optional :force, type: Boolean, desc: 'Skip feature flag validation checks, ie. YAML definition'

        mutually_exclusive :key, :feature_group
        mutually_exclusive :key, :user
        mutually_exclusive :key, :group
        mutually_exclusive :key, :project
      end
      post ':name' do
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

      desc 'Remove the gate value for the given feature'
      delete ':name' do
        Feature.remove(params[:name])

        no_content!
      end
    end

    helpers do
      def validate_feature_flag_name!(name)
        # no-op
      end
    end
  end
end

API::Features.prepend_mod_with('API::Features')
