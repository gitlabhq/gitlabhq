# frozen_string_literal: true

Gitlab::Experiment.configure do |config|
  config.base_class = 'ApplicationExperiment'
  config.cache = ApplicationExperiment::Cache.new
end
