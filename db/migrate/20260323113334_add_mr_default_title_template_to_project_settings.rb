# frozen_string_literal: true

class AddMrDefaultTitleTemplateToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :project_settings, :mr_default_title_template, :text, null: true, if_not_exists: true
    end

    add_text_limit :project_settings, :mr_default_title_template, 100, validate: false
  end

  def down
    remove_column :project_settings, :mr_default_title_template, if_exists: true
  end
end
