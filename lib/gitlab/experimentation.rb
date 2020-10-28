# frozen_string_literal: true

require 'zlib'

# == Experimentation
#
# Utility module for A/B testing experimental features. Define your experiments in the `EXPERIMENTS` constant.
# Experiment options:
# - environment (optional, defaults to enabled for development and GitLab.com)
# - tracking_category (optional, used to set the category when tracking an experiment event)
# - use_backwards_compatible_subject_index (optional, set this to true if you need backwards compatibility)
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
        tracking_category: 'Growth::Acquisition::Experiment::SignUpFlow',
        use_backwards_compatible_subject_index: true
      },
      onboarding_issues: {
        tracking_category: 'Growth::Conversion::Experiment::OnboardingIssues',
        use_backwards_compatible_subject_index: true
      },
      ci_notification_dot: {
        tracking_category: 'Growth::Expansion::Experiment::CiNotificationDot',
        use_backwards_compatible_subject_index: true
      },
      upgrade_link_in_user_menu_a: {
        tracking_category: 'Growth::Expansion::Experiment::UpgradeLinkInUserMenuA',
        use_backwards_compatible_subject_index: true
      },
      invite_members_version_a: {
        tracking_category: 'Growth::Expansion::Experiment::InviteMembersVersionA',
        use_backwards_compatible_subject_index: true
      },
      invite_members_version_b: {
        tracking_category: 'Growth::Expansion::Experiment::InviteMembersVersionB',
        use_backwards_compatible_subject_index: true
      },
      invite_members_empty_group_version_a: {
        tracking_category: 'Growth::Expansion::Experiment::InviteMembersEmptyGroupVersionA',
        use_backwards_compatible_subject_index: true
      },
      new_create_project_ui: {
        tracking_category: 'Manage::Import::Experiment::NewCreateProjectUi',
        use_backwards_compatible_subject_index: true
      },
      contact_sales_btn_in_app: {
        tracking_category: 'Growth::Conversion::Experiment::ContactSalesInApp',
        use_backwards_compatible_subject_index: true
      },
      customize_homepage: {
        tracking_category: 'Growth::Expansion::Experiment::CustomizeHomepage',
        use_backwards_compatible_subject_index: true
      },
      invite_email: {
        tracking_category: 'Growth::Acquisition::Experiment::InviteEmail',
        use_backwards_compatible_subject_index: true
      },
      invitation_reminders: {
        tracking_category: 'Growth::Acquisition::Experiment::InvitationReminders',
        use_backwards_compatible_subject_index: true
      },
      group_only_trials: {
        tracking_category: 'Growth::Conversion::Experiment::GroupOnlyTrials',
        use_backwards_compatible_subject_index: true
      },
      default_to_issues_board: {
        tracking_category: 'Growth::Conversion::Experiment::DefaultToIssuesBoard',
        use_backwards_compatible_subject_index: true
      }
    }.freeze

    GROUP_CONTROL = :control
    GROUP_EXPERIMENTAL = :experimental

    # Controller concern that checks if an `experimentation_subject_id cookie` is present and sets it if absent.
    # Used for A/B testing of experimental features. Exposes the `experiment_enabled?(experiment_name)` method
    # to controllers and views. It returns true when the experiment is enabled and the user is selected as part
    # of the experimental group.
    #
    module ControllerConcern
      extend ActiveSupport::Concern

      included do
        before_action :set_experimentation_subject_id_cookie, unless: :dnt_enabled?
        helper_method :experiment_enabled?, :experiment_tracking_category_and_group
      end

      def set_experimentation_subject_id_cookie
        return if cookies[:experimentation_subject_id].present?

        cookies.permanent.signed[:experimentation_subject_id] = {
          value: SecureRandom.uuid,
          secure: ::Gitlab.config.gitlab.https,
          httponly: true
        }
      end

      def push_frontend_experiment(experiment_key)
        var_name = experiment_key.to_s.camelize(:lower)
        enabled = experiment_enabled?(experiment_key)

        gon.push({ experiments: { var_name => enabled } }, true)
      end

      def experiment_enabled?(experiment_key)
        return false if dnt_enabled?

        return true if Experimentation.enabled_for_value?(experiment_key, experimentation_subject_index(experiment_key))
        return true if forced_enabled?(experiment_key)

        false
      end

      def track_experiment_event(experiment_key, action, value = nil)
        return if dnt_enabled?

        track_experiment_event_for(experiment_key, action, value) do |tracking_data|
          ::Gitlab::Tracking.event(tracking_data.delete(:category), tracking_data.delete(:action), **tracking_data)
        end
      end

      def frontend_experimentation_tracking_data(experiment_key, action, value = nil)
        return if dnt_enabled?

        track_experiment_event_for(experiment_key, action, value) do |tracking_data|
          gon.push(tracking_data: tracking_data)
        end
      end

      def record_experiment_user(experiment_key)
        return if dnt_enabled?
        return unless Experimentation.enabled?(experiment_key) && current_user

        ::Experiment.add_user(experiment_key, tracking_group(experiment_key), current_user)
      end

      def experiment_tracking_category_and_group(experiment_key)
        "#{tracking_category(experiment_key)}:#{tracking_group(experiment_key, '_group')}"
      end

      private

      def dnt_enabled?
        Gitlab::Utils.to_boolean(request.headers['DNT'])
      end

      def experimentation_subject_id
        cookies.signed[:experimentation_subject_id]
      end

      def experimentation_subject_index(experiment_key)
        return if experimentation_subject_id.blank?

        if Experimentation.experiment(experiment_key).use_backwards_compatible_subject_index
          experimentation_subject_id.delete('-').hex % 100
        else
          Zlib.crc32("#{experiment_key}#{experimentation_subject_id}") % 100
        end
      end

      def track_experiment_event_for(experiment_key, action, value)
        return unless Experimentation.enabled?(experiment_key)

        yield experimentation_tracking_data(experiment_key, action, value)
      end

      def experimentation_tracking_data(experiment_key, action, value)
        {
          category: tracking_category(experiment_key),
          action: action,
          property: tracking_group(experiment_key, "_group"),
          label: experimentation_subject_id,
          value: value
        }.compact
      end

      def tracking_category(experiment_key)
        Experimentation.experiment(experiment_key).tracking_category
      end

      def tracking_group(experiment_key, suffix = nil)
        return unless Experimentation.enabled?(experiment_key)

        group = experiment_enabled?(experiment_key) ? GROUP_EXPERIMENTAL : GROUP_CONTROL

        suffix ? "#{group}#{suffix}" : group
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
        experiment.enabled_for_environment? && experiment.enabled?
      end

      def enabled_for_attribute?(experiment_key, attribute)
        index = Digest::SHA1.hexdigest(attribute).hex % 100
        enabled_for_value?(experiment_key, index)
      end

      def enabled_for_value?(experiment_key, value)
        enabled?(experiment_key) && experiment(experiment_key).enabled_for_index?(value)
      end
    end

    Experiment = Struct.new(
      :key,
      :environment,
      :tracking_category,
      :use_backwards_compatible_subject_index,
      keyword_init: true
    ) do
      def enabled?
        experiment_percentage > 0
      end

      def enabled_for_environment?
        return ::Gitlab.dev_env_or_com? if environment.nil?

        environment
      end

      def enabled_for_index?(index)
        return false if index.blank?

        index <= experiment_percentage
      end

      private

      # When a feature does not exist, the `percentage_of_time_value` method will return 0
      def experiment_percentage
        @experiment_percentage ||= Feature.get(:"#{key}_experiment_percentage").percentage_of_time_value # rubocop:disable Gitlab/AvoidFeatureGet
      end
    end
  end
end
