# frozen_string_literal: true

Gitlab::Experiment.configure do |config|
  config.base_class = 'ApplicationExperiment'
  config.mount_at = '/-/experiment'
  config.cache = Gitlab::Experiment::Cache::RedisHashStore.new(
    pool: ->(&block) { Gitlab::Redis::SharedState.with { |redis| block.call(redis) } }
  )
  config.tracking_behavior = lambda do |action, event_args|
    Gitlab::Tracking.event(name, action.to_s, **event_args.merge(
      context: (event_args[:context] || []) << SnowplowTracker::SelfDescribingJson.new(
        'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0', signature
      )
    ))
  end
end
