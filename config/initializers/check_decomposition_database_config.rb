# frozen_string_literal: true

ci_db_config = Gitlab::Application.config.database_configuration[Rails.env]["ci"]

if ci_db_config.present?
  raise "migrations_paths setting for ci database must be `db/ci_migrate`" unless ci_db_config["migrations_paths"] == 'db/ci_migrate'
end
