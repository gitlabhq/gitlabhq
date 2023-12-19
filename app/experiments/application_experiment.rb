# frozen_string_literal: true

class ApplicationExperiment < Gitlab::Experiment
  control { nil } # provide a default control for anonymous experiments

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

  def control_behavior
    # define a default nil control behavior so we can omit it when not needed
  end

  # This is deprecated logic as of v0.6.0 and should eventually be removed, but
  # needs to stay intact for actively running experiments. The new strategy
  # utilizes Digest::SHA2, a secret seed, and generates a 64-byte string.
  #
  # https://gitlab.com/gitlab-org/gitlab/-/issues/334590
  #
  # @deprecated
  def key_for(source, seed = name)
    # If FIPS is enabled, we simply call the method available in the gem, which
    # uses SHA2.
    return super if Gitlab::FIPS.enabled?

    # If FIPS isn't enabled, we use the legacy MD5 logic to keep existing
    # experiment events working.
    source = source.keys + source.values if source.is_a?(Hash)
    Digest::MD5.hexdigest(Array(source).map { |v| identify(v) }.unshift(seed).join('|'))
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
