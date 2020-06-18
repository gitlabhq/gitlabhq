# frozen_string_literal: true

# == Experimentation
#
# Utility module for A/B testing experimental features. Define your experiments in the `EXPERIMENTS` constant.
# Experiment options:
# - environment (optional, defaults to enabled for development and GitLab.com)
# - tracking_category (optional, used to set the category when tracking an experiment event)
#
# The experiment is controlled by a Feature Flag (https://docs.gitlab.com/ee/development/feature_flags/controls.html),
# which is named "#{experiment_key}_experiment_percentage" and *must* be set with a percentage and not be used for other purposes.
#
# To enable the experiment for 10% of the users:
#
# chatops: `/chatops run feature set experiment_key_experiment_percentage 10`
# console: `Feature.enable_percentage_of_time(:experiment_key_experiment_percentage, 10)`
#
# To disable the experiment:
#
# chatops: `/chatops run feature delete experiment_key_experiment_percentage`
# console: `Feature.remove(:experiment_key_experiment_percentage)`
#
# To check the current rollout percentage:
#
# chatops: `/chatops run feature get experiment_key_experiment_percentage`
# console: `Feature.get(:experiment_key_experiment_percentage).percentage_of_time_value`
#

# TODO: see https://gitlab.com/gitlab-org/gitlab/-/issues/217490
module Gitlab
  module Experimentation
    EXPERIMENTS = {
      signup_flow: {
        tracking_category: 'Growth::Acquisition::Experiment::SignUpFlow'
      },
      onboarding_issues: {
        tracking_category: 'Growth::Conversion::Experiment::OnboardingIssues'
      },
      suggest_pipeline: {
        tracking_category: 'Growth::Expansion::Experiment::SuggestPipeline'
      },
      ci_notification_dot: {
        tracking_category: 'Growth::Expansion::Experiment::CiNotificationDot'
      },
      buy_ci_minutes_version_a: {
        tracking_category: 'Growth::Expansion::Experiment::BuyCiMinutesVersionA'
      },
      upgrade_link_in_user_menu_a: {
        tracking_category: 'Growth::Expansion::Experiment::UpgradeLinkInUserMenuA'
      },
      invite_members_version_a: {
        tracking_category: 'Growth::Expansion::Experiment::InviteMembersVersionA'
      },
      new_create_project_ui: {
        tracking_category: 'Manage::Import::Experiment::NewCreateProjectUi'
      }
    }.freeze

    # Controller concern that checks if an `experimentation_subject_id cookie` is present and sets it if absent.
    # Used for A/B testing of experimental features. Exposes the `experiment_enabled?(experiment_name)` method
    # to controllers and views. It returns true when the experiment is enabled and the user is selected as part
    # of the experimental group.
    #
    module ControllerConcern
      extend ActiveSupport::Concern

      included do
        before_action :set_experimentation_subject_id_cookie, unless: :dnt_enabled?
        helper_method :experiment_enabled?
      end

      def set_experimentation_subject_id_cookie
        return if cookies[:experimentation_subject_id].present?

        cookies.permanent.signed[:experimentation_subject_id] = {
          value: SecureRandom.uuid,
          secure: ::Gitlab.config.gitlab.https,
          httponly: true
        }
      end

      def experiment_enabled?(experiment_key)
        return false if dnt_enabled?

        return true if Experimentation.enabled_for_user?(experiment_key, experimentation_subject_index)
        return true if forced_enabled?(experiment_key)

        false
      end

      def track_experiment_event(experiment_key, action, value = nil)
        track_experiment_event_for(experiment_key, action, value) do |tracking_data|
          ::Gitlab::Tracking.event(tracking_data.delete(:category), tracking_data.delete(:action), tracking_data)
        end
      end

      def frontend_experimentation_tracking_data(experiment_key, action, value = nil)
        track_experiment_event_for(experiment_key, action, value) do |tracking_data|
          gon.push(tracking_data: tracking_data)
        end
      end

      private

      def dnt_enabled?
        Gitlab::Utils.to_boolean(request.headers['DNT'])
      end

      def experimentation_subject_id
        cookies.signed[:experimentation_subject_id]
      end

      def experimentation_subject_index
        return if experimentation_subject_id.blank?

        experimentation_subject_id.delete('-').hex % 100
      end

      def track_experiment_event_for(experiment_key, action, value)
        return unless Experimentation.enabled?(experiment_key)

        yield experimentation_tracking_data(experiment_key, action, value)
      end

      def experimentation_tracking_data(experiment_key, action, value)
        {
          category: tracking_category(experiment_key),
          action: action,
          property: tracking_group(experiment_key),
          label: experimentation_subject_id,
          value: value
        }.compact
      end

      def tracking_category(experiment_key)
        Experimentation.experiment(experiment_key).tracking_category
      end

      def tracking_group(experiment_key)
        return unless Experimentation.enabled?(experiment_key)

        experiment_enabled?(experiment_key) ? 'experimental_group' : 'control_group'
      end

      def forced_enabled?(experiment_key)
        params.has_key?(:force_experiment) && params[:force_experiment] == experiment_key.to_s
      end
    end

    class << self
      def experiment(key)
        Experiment.new(EXPERIMENTS[key].merge(key: key))
      end

      def enabled?(experiment_key)
        return false unless EXPERIMENTS.key?(experiment_key)

        experiment = experiment(experiment_key)
        experiment.enabled? && experiment.enabled_for_environment?
      end

      def enabled_for_user?(experiment_key, experimentation_subject_index)
        enabled?(experiment_key) &&
          experiment(experiment_key).enabled_for_experimentation_subject?(experimentation_subject_index)
      end
    end

    Experiment = Struct.new(:key, :environment, :tracking_category, keyword_init: true) do
      def enabled?
        experiment_percentage.positive?
      end

      def enabled_for_environment?
        return ::Gitlab.dev_env_or_com? if environment.nil?

        environment
      end

      def enabled_for_experimentation_subject?(experimentation_subject_index)
        return false if experimentation_subject_index.blank?

        experimentation_subject_index <= experiment_percentage
      end

      private

      # When a feature does not exist, the `percentage_of_time_value` method will return 0
      def experiment_percentage
        @experiment_percentage ||= Feature.get(:"#{key}_experiment_percentage").percentage_of_time_value # rubocop:disable Gitlab/AvoidFeatureGet
      end
    end
  end
end
