# frozen_string_literal: true

Gitlab::Experiment.configure do |config|
  # The base experiment class that will be instantiated when using the
  # `experiment` DSL, is our ApplicationExperiment. If a custom experiment
  # class is resolvable by the experiment name, that will be instantiated
  # instead -- which can then inherit from whatever else it wants to.
  #
  # Custom experiment classes can be defined in /app/experiments.
  #
  config.base_class = 'ApplicationExperiment'

  # Customize the logic of our default rollout, which shouldn't include
  # assigning the control yet -- we specifically set it to false for now.
  #
  config.default_rollout = Gitlab::Experiment::Rollout.resolve('Gitlab::ExperimentFeatureRollout')

  # Mount the engine and middleware at a gitlab friendly style path.
  #
  # The middleware currently focuses only on handling redirection logic, which
  # is used for instrumenting urls in places where urls are otherwise not
  # possible to instrument. Emails, and markdown content being among the top
  # places where this can be useful.
  #
  config.mount_at = '/-/experiment'

  # We use a long lived redis cache to increase the performance of experiments.
  #
  # Experiments can implement exclusionary and segmentation logic that can be
  # expensive, and so to better handle these cases, once a variant is assigned
  # to a given context, it's "sticky" to that context. This cache check is one
  # of the first things in the process of variant resolution, and so if one is
  # cached, no further logic is executed in resolving variant assignment.
  #
  # This means that there's no easy way to currently move a context from one
  # variant to another. Future tooling will make this easier, but implementing
  # a custom cache for your experiment may be required in edge cases.
  #
  config.cache = Gitlab::Experiment::Cache::RedisHashStore.new(
    pool: ->(&block) { Gitlab::Redis::SharedState.with(&block) }
  )

  # The middleware instruments and redirects urls, but we don't want this to be
  # exploited or used to send people from a trusted site to a nefarious one. So
  # we validate urls before redirecting them.
  #
  # This behavior doesn't make perfect sense for self managed installs either,
  # so we don't think we should redirect in those cases.
  #
  valid_domains = %w[about.gitlab.com docs.gitlab.com gitlab.com gdk.test localhost]
  config.redirect_url_validator = ->(url) do
    ApplicationExperiment.available? && (url = URI.parse(url)) && valid_domains.include?(url.host)
  rescue URI::InvalidURIError
    false
  end

  # Experiments are instrumented using an event based system by default. This
  # can be overridden in your experiment by specifying a `#track` method.
  #
  # The basic behavior though, is to accept any details and pass them along to
  # snowplow, with an included gitlab_experiment schema, that has various
  # details about the experiment, like name and variant assignment.
  #
  # This uses the Gitlab::Tracking interface, so arbitrary event properties are
  # permitted, and will be sent along using Gitlab::Tracking::StandardContext.
  #
  config.tracking_behavior = ->(action, event_args) do
    Gitlab::Tracking.event(name, action, **event_args.merge(
      context: (event_args[:context] || []) << SnowplowTracker::SelfDescribingJson.new(
        'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0', signature
      )
    ))
  end

  # Deprecation warnings resolution for 0.7.0
  #
  # We're working through deprecation warnings one by one in:
  # https://gitlab.com/gitlab-org/gitlab/-/issues/350944
  #
  config.singleton_class.prepend(Module.new do
    # Disable all deprecations in non dev/test environments.
    #
    def deprecated(*args, version:, stack: 0)
      super if Gitlab.dev_or_test_env?
    end
  end)
end
