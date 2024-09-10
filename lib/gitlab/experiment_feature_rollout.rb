# frozen_string_literal: true

module Gitlab
  class ExperimentFeatureRollout < Gitlab::Experiment::Rollout::Percent
    # For this rollout strategy to consider an experiment as enabled, we
    # must:
    #
    # - have a feature flag yaml file that declares it.
    # - be in an environment that permits it.
    # - not have rolled out the feature flag at all (no percent of actors,
    #   no inclusions, etc.)
    def enabled?
      return false unless feature_flag_defined?
      return false unless available?
      return false unless ::Feature.enabled?(:gitlab_experiment, type: :ops)

      feature_flag_instance.state != :off
    end

    # For assignment we first check to see if our feature flag is enabled
    # for "self". This is done by calling `#flipper_id` (used behind the
    # scenes by `Feature`). By default this is our `experiment.id` (or more
    # specifically, the context key, which is an anonymous SHA generated
    # using the details of an experiment.
    #
    # If the `Feature.enabled?` check is false, we return nil implicitly,
    # which will assign the control. Otherwise we call super, which will
    # assign a variant based on our provided distribution rules.
    # Otherwise we will assign a variant evenly across the behaviours without control.
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
