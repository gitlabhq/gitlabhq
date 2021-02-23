# frozen_string_literal: true

Gitlab::Experiment.configure do |config|
  config.base_class = 'ApplicationExperiment'
  config.cache = Gitlab::Experiment::Cache::RedisHashStore.new(
    pool: ->(&block) { Gitlab::Redis::SharedState.with { |redis| block.call(redis) } }
  )
end
