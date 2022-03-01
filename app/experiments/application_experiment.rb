# frozen_string_literal: true

class ApplicationExperiment < Gitlab::Experiment
  control { nil } # provide a default control for anonymous experiments

  def publish_to_database
    ActiveSupport::Deprecation.warn('publish_to_database is deprecated and should not be used for reporting anymore')

    return unless should_track?

    # if the context contains a namespace, group, project, user, or actor
    value = context.value
    subject = value[:namespace] || value[:group] || value[:project] || value[:user] || value[:actor]
    return unless ExperimentSubject.valid_subject?(subject)

    variant_name = :experimental if variant&.name != 'control'
    Experiment.add_subject(name, variant: variant_name || :control, subject: subject)
  end

  def control_behavior
    # define a default nil control behavior so we can omit it when not needed
  end

  # TODO: remove
  # This is deprecated logic as of v0.6.0 and should eventually be removed, but
  # needs to stay intact for actively running experiments. The new strategy
  # utilizes Digest::SHA2, a secret seed, and generates a 64-byte string.
  def key_for(source, seed = name)
    source = source.keys + source.values if source.is_a?(Hash)

    ingredients = Array(source).map { |v| identify(v) }
    ingredients.unshift(seed)

    Digest::MD5.hexdigest(ingredients.join('|'))
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
