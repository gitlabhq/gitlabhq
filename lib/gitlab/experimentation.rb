# frozen_string_literal: true

# == Experimentation
#
# Utility module for A/B testing experimental features. Define your experiments in the `EXPERIMENTS` constant.
# Experiment options:
# - tracking_category (optional, used to set the category when tracking an experiment event)
# - use_backwards_compatible_subject_index (optional, set this to true if you need backwards compatibility -- you likely do not need this, see note in the next paragraph.)
# - rollout_strategy: default is `:cookie` based rollout. We may also set it to `:user` based rollout
#
# Using the backwards-compatible subject index (use_backwards_compatible_subject_index option):
# This option was added when [the calculation of experimentation_subject_index was changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45733/diffs#41af4a6fa5a10c7068559ce21c5188483751d934_157_173). It is not intended to be used by new experiments, it exists merely for the segmentation integrity of in-flight experiments at the time the change was deployed. That is, we want users who were assigned to the "experimental" group or the "control" group before the change to still be in those same groups after the change. See [the original issue](https://gitlab.com/gitlab-org/gitlab/-/issues/270858) and [this related comment](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/48110#note_458223745) for more information.
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
      invite_members_empty_group_version_a: {
        tracking_category: 'Growth::Expansion::Experiment::InviteMembersEmptyGroupVersionA',
        use_backwards_compatible_subject_index: true
      },
      contact_sales_btn_in_app: {
        tracking_category: 'Growth::Conversion::Experiment::ContactSalesInApp',
        use_backwards_compatible_subject_index: true
      },
      remove_known_trial_form_fields: {
        tracking_category: 'Growth::Conversion::Experiment::RemoveKnownTrialFormFields'
      },
      invite_members_new_dropdown: {
        tracking_category: 'Growth::Expansion::Experiment::InviteMembersNewDropdown'
      },
      show_trial_status_in_sidebar: {
        tracking_category: 'Growth::Conversion::Experiment::ShowTrialStatusInSidebar',
        rollout_strategy: :group
      },
      trial_onboarding_issues: {
        tracking_category: 'Growth::Conversion::Experiment::TrialOnboardingIssues'
      },
      learn_gitlab_a: {
        tracking_category: 'Growth::Conversion::Experiment::LearnGitLabA',
        rollout_strategy: :user
      },
      learn_gitlab_b: {
        tracking_category: 'Growth::Activation::Experiment::LearnGitLabB',
        rollout_strategy: :user
      }
    }.freeze

    class << self
      def get_experiment(experiment_key)
        return unless EXPERIMENTS.key?(experiment_key)

        ::Gitlab::Experimentation::Experiment.new(experiment_key, **EXPERIMENTS[experiment_key])
      end

      def active?(experiment_key)
        experiment = get_experiment(experiment_key)
        return false unless experiment

        experiment.active?
      end

      def in_experiment_group?(experiment_key, subject:)
        return false if subject.blank?
        return false unless active?(experiment_key)

        log_invalid_rollout(experiment_key, subject)

        experiment = get_experiment(experiment_key)
        return false unless experiment

        experiment.enabled_for_index?(index_for_subject(experiment, subject))
      end

      def rollout_strategy(experiment_key)
        experiment = get_experiment(experiment_key)
        return unless experiment

        experiment.rollout_strategy
      end

      def log_invalid_rollout(experiment_key, subject)
        return if valid_subject_for_rollout_strategy?(experiment_key, subject)

        logger = Gitlab::ExperimentationLogger.build
        logger.warn message: 'Subject must conform to the rollout strategy',
                     experiment_key: experiment_key,
                     subject: subject.class.to_s,
                     rollout_strategy: rollout_strategy(experiment_key)
      end

      def valid_subject_for_rollout_strategy?(experiment_key, subject)
        case rollout_strategy(experiment_key)
        when :user
          subject.is_a?(User)
        when :group
          subject.is_a?(Group)
        when :cookie
          subject.nil? || subject.is_a?(String)
        else
          false
        end
      end

      private

      def index_for_subject(experiment, subject)
        index = if experiment.use_backwards_compatible_subject_index
                  Digest::SHA1.hexdigest(subject_id(subject)).hex
                else
                  Zlib.crc32("#{experiment.key}#{subject_id(subject)}")
                end

        index % 100
      end

      def subject_id(subject)
        if subject.respond_to?(:to_global_id)
          subject.to_global_id.to_s
        elsif subject.respond_to?(:to_s)
          subject.to_s
        else
          raise ArgumentError, 'Subject must respond to `to_global_id` or `to_s`'
        end
      end
    end
  end
end
