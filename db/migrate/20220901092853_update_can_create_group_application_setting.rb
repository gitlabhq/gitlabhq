# frozen_string_literal: true

class UpdateCanCreateGroupApplicationSetting < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    value = gitlab_config.respond_to?(:default_can_create_group) ? gitlab_config.default_can_create_group : true
    value = Gitlab::Utils.to_boolean(value, default: true)

    execute_update(value: value)
  end

  def down
    execute_update(value: true)
  end

  private

  def execute_update(value:)
    execute "UPDATE application_settings SET can_create_group = #{value}"
  end

  def gitlab_config
    Gitlab.config.gitlab
  end
end
