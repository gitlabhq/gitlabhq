# frozen_string_literal: true

class AddAiCustomInstructionsToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespace_settings, :ai_custom_instructions, :text, null: true, if_not_exists: true
    end

    add_text_limit :namespace_settings, :ai_custom_instructions, 2000, validate: false

    prepare_async_check_constraint_validation :namespace_settings,
      name: check_constraint_name(:namespace_settings, :ai_custom_instructions, 'max_length')
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :ai_custom_instructions, if_exists: true
    end
  end
end
