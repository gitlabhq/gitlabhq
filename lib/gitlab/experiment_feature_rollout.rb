# frozen_string_literal: true

module Gitlab
  class ExperimentFeatureRollout < Gitlab::Experiment::Rollout::Percent
    # For this rollout strategy to consider an experiment as enabled, we
    # must:
    #
    # - have a feature flag yaml file that declares it.
    # - be in an environment that permits it.
    # - have the feature flag in any state of enablement (can be fully
    #   or partially rolled out with percentages, actors, etc.)
    def enabled?
      return false unless feature_flag_defined?
      return false unless available?
      return false unless ::Feature.enabled?(:gitlab_experiment, type: :ops)

      feature_flag_instance.state != :off
    end

    # For assignment we first check to see if our feature flag is enabled
    # for this rollout instance. Feature.enabled? calls below `#flipper_id` to get a unique identifier.
    # By default #flipper_id returns `Experiment;#{experiment.id}` where experiment.id
    # is an anonymous SHA generated using details of the experiment.
    # This ensures deterministic assignment - same actor always gets same result.
    #
    # If the `Feature.enabled?` check is false, we return nil implicitly,
    # which will assign the control. If it returns true, we call super to
    # assign a variant based on the experiment's distribution rules (if specified)
    # or evenly across all non-control variants (default behavior of Gitlab::Experiment::Rollout::Percent).
    #
    # Since we exclude :control from #behavior_names, the feature flag's
    # rollout percentage determines the split: e.g., 30% flag rollout means
    # 70% get control (flag disabled) and 30% get variants (flag enabled).
    def execute_assignment
      super if ::Feature.enabled?(feature_flag_name, self, type: :experiment)
    end

    # This is what's provided to the `Feature.enabled?` call that will be
    # used to determine experiment inclusion. An experiment may provide an
    # override for this method to make the experiment work on user, group,
    # or projects.
    #
    # For example, when running an experiment on a project, you could make
    # the experiment assignable by project (using chatops) by implementing
    # a `flipper_id` method in the experiment:
    #
    # def flipper_id
    #   context.project.flipper_id
    # end
    #
    # Or even cleaner, simply delegate it:
    #
    # delegate :flipper_id, to: -> { context.project }
    def flipper_id
      return experiment.flipper_id if experiment.respond_to?(:flipper_id)

      "Experiment;#{id}"
    end

    private

    def available?
      ApplicationExperiment.available?
    end

    def feature_flag_instance
      ::Feature.get(feature_flag_name) # rubocop:disable Gitlab/AvoidFeatureGet -- We are using at a lower layer here in experiment framework
    end

    def feature_flag_defined?
      ::Feature::Definition.get(feature_flag_name).present?
    end

    def feature_flag_name
      experiment.name.tr('/', '_')
    end

    def behavior_names
      super - [:control]
    end
  end
end
