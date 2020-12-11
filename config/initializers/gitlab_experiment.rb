# frozen_string_literal: true

Gitlab::Experiment.configure do |config|
  # Logic this project uses to resolve a variant for a given experiment.
  #
  # This can return an instance of any object that responds to `name`, or can
  # return a variant name as a symbol or string.
  #
  # This block will be executed within the scope of the experiment instance,
  # so can easily access experiment methods, like getting the name or context.
  config.variant_resolver = lambda do |requested_variant|
    # Return the variant if one was requested in code:
    break requested_variant if requested_variant.present?

    # Use Feature interface to determine the variant by passing the experiment,
    # which responds to `flipper_id` and `session_id` to accommodate adapters.
    variant_names.first if Feature.enabled?(name, self, type: :experiment)
  end

  # Tracking behavior can be implemented to link an event to an experiment.
  #
  # Similar to the variant_resolver, this is called within the scope of the
  # experiment instance and so can access any methods on the experiment,
  # such as name and signature.
  config.tracking_behavior = lambda do |event, args|
    Gitlab::Tracking.event(name, event.to_s, **args.merge(
      context: (args[:context] || []) << SnowplowTracker::SelfDescribingJson.new(
        'iglu:com.gitlab/gitlab_experiment/jsonschema/0-3-0', signature
      )
    ))
  end

  # Called at the end of every experiment run, with the result.
  #
  # You may want to track that you've assigned a variant to a given context,
  # or push the experiment into the client or publish results elsewhere, like
  # into redis or postgres. Also called within the scope of the experiment
  # instance.
  config.publishing_behavior = lambda do |result|
    # Track the event using our own configured tracking logic.
    track(:assignment)

    # Push the experiment knowledge into the front end. The signature contains
    # the context key, and the variant that has been determined.
    Gon.push({ experiment: { name => signature } }, true)
  end
end
