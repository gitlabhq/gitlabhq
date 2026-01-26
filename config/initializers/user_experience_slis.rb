# frozen_string_literal: true

Labkit::UserExperienceSli.configure do |config|
  # By default Puma starts in the tmp directory to mimic Omnibus GitLab.
  # The root path needs to be set here for Labkit to identify it properly,
  # otherwise it will be tmp/config/user_experience_slis.
  config.registry_path = Rails.root.join("config/user_experience_slis")
  config.logger = Labkit::Logging::JsonLogger.new(Rails.root.join("log/user_experience_slis.log"))
end

json_schema_key = "https://gitlab.com/gitlab-org/gitlab/-/raw/master/config/feature_categories/schema.json"
# We have control over the file content, so it's safe to use parse here
feature_categories_json_schema = Gitlab::Json.parse(Rails.root.join("config/feature_categories/schema.json").read) # rubocop:disable Gitlab/JsonSafeParse -- trusted file content
Labkit::JsonSchema::RefResolver.cache[json_schema_key] = feature_categories_json_schema
