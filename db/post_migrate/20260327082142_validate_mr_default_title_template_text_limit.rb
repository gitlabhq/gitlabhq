# frozen_string_literal: true

class ValidateMrDefaultTitleTemplateTextLimit < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  def up
    validate_text_limit :project_settings, :mr_default_title_template
  end

  def down
    # No-op: validation removal is handled by constraint removal
  end
end
