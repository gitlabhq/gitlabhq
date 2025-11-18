# frozen_string_literal: true

Labkit::UserExperienceSli.configure do |config|
  # By default Puma starts in the tmp directory to mimic Omnibus GitLab.
  # The root path needs to be set here for Labkit to identify it properly,
  # otherwise it will be tmp/config/user_experience_slis.
  config.registry_path = Rails.root.join("config/user_experience_slis")
  config.logger = Labkit::Logging::JsonLogger.new(Rails.root.join("log/user_experience_slis.log"))
end
