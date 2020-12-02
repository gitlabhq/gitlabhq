# frozen_string_literal: true

# == Experimentation
#
# Utility module for A/B testing experimental features. Define your experiments in the `EXPERIMENTS` constant.
# Experiment options:
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
      },
      jobs_empty_state: {
        tracking_category: 'Growth::Activation::Experiment::JobsEmptyState'
      }
    }.freeze

    class << self
      def experiment(key)
        Gitlab::Experimentation::Experiment.new(key, **EXPERIMENTS[key])
      end

      def enabled?(experiment_key)
        return false unless EXPERIMENTS.key?(experiment_key)

        experiment(experiment_key).enabled?
      end

      def enabled_for_attribute?(experiment_key, attribute)
        index = Digest::SHA1.hexdigest(attribute).hex % 100
        enabled_for_value?(experiment_key, index)
      end

      def enabled_for_value?(experiment_key, value)
        enabled?(experiment_key) && experiment(experiment_key).enabled_for_index?(value)
      end
    end
  end
end
