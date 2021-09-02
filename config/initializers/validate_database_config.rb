# frozen_string_literal: true

if Gitlab::Utils.to_boolean(ENV['SKIP_DATABASE_CONFIG_VALIDATION'], default: false)
  return
end

if Rails.application.config.uses_legacy_database_config
  warn "WARNING: This installation of GitLab uses a deprecated syntax for 'config/database.yml'. " \
    "The support for this syntax will be removed in 15.0. " \
    "More information can be found here: https://gitlab.com/gitlab-org/gitlab/-/issues/338182"
end

if configurations = ActiveRecord::Base.configurations.configurations
  if configurations.first.name != Gitlab::Database::MAIN_DATABASE_NAME
    raise "ERROR: This installation of GitLab uses unsupported 'config/database.yml'. " \
      "The `main:` database needs to be defined as a first configuration item instead of `#{configurations.first.name}`."
  end

  rejected_config_names = configurations.map(&:name).to_set - Gitlab::Database::DATABASE_NAMES
  if rejected_config_names.any?
    raise "ERROR: This installation of GitLab uses unsupported database names " \
      "in 'config/database.yml': #{rejected_config_names.to_a.join(", ")}. The only supported ones are " \
      "#{Gitlab::Database::DATABASE_NAMES.join(", ")}."
  end

  replicas_config_names = configurations.select(&:replica?).map(&:name)
  if replicas_config_names.any?
    raise "ERROR: This installation of GitLab uses unsupported database configuration " \
      "with 'replica: true' parameter in 'config/database.yml' for: #{replicas_config_names.join(", ")}"
  end
end
