# frozen_string_literal: true

class ApplicationExperiment < Gitlab::Experiment
  control { nil } # provide a default control for anonymous experiments

  # When testing experiments that define control and candidate variants,
  # use the 'defines control and candidate variants' shared example from
  # spec/support/shared_examples/experiments/default_experiment_variants_shared_examples.rb
  # After adding tests, verify rubocop passes by running: rubocop --only ExperimentsTestCoverage

  # We have experiments in ce/foss code even though they will never be available
  # for ce/foss instances.
  # We do that since we currently only experiment on the ee with SaaS instance.
  # However, if the experiment is successful, we may commit the final code to ce/foss
  # if the feature we are experimenting on is not a licensed or SaaS feature.
  #
  # This follows the https://docs.gitlab.com/ee/development/ee_features.html
  # guidelines and therefore we have hardcoded `false` here.
  def self.available?
    false
  end

  # The context keys that form this experiment's cache key signature. Read by
  # Experiments::AssignmentService to reconstruct the cache key when reading
  # assignments through the experiments API. Each concrete experiment must
  # override this with the symbol keys it uses, in the same order as the
  # keyword arguments in its `experiment()` call, since GLEX derives cache
  # keys from the ordered context:
  #
  #   class MyExperiment < ApplicationExperiment
  #     def self.context_keys = %i[user namespace]
  #   end
  #
  #   experiment(:my_experiment, user: user, namespace: namespace)
  #
  def self.context_keys
    raise Gitlab::AbstractMethodError, "#{name} must define `self.context_keys`"
  end

  def control_behavior
    # define a default nil control behavior so we can omit it when not needed
  end

  def nest_experiment(other)
    instance_exec(:nested, { label: other.name }, &Configuration.tracking_behavior)
  end

  private

  def tracking_context(event_args)
    {
      namespace: context.try(:namespace) || context.try(:group),
      project: context.try(:project),
      user: user_or_actor
    }.merge(event_args)
  end

  def user_or_actor
    actor = context.try(:actor)
    actor.respond_to?(:id) ? actor : context.try(:user)
  end
end

ApplicationExperiment.prepend_mod
