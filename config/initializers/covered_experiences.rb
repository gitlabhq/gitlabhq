# frozen_string_literal: true

Labkit::CoveredExperience.configure do |config|
  # By default Puma starts in the tmp directory to mimic Omnibus GitLab.
  # The root path needs to be set here for Labkit to identify it properly,
  # otherwise it will be tmp/config/covered_experiences.
  config.registry_path = Rails.root.join("config/covered_experiences")
  config.logger = Labkit::Logging::JsonLogger.new(Rails.root.join("log/covered_experiences.log"))
end
