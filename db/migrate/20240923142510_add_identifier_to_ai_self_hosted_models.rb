# frozen_string_literal: true

class AddIdentifierToAiSelfHostedModels < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.5'

  def up
    add_column :ai_self_hosted_models, :identifier, :text, null: true, if_not_exists: true

    add_text_limit :ai_self_hosted_models, :identifier, 255
  end

  def down
    remove_column :ai_self_hosted_models, :identifier, if_exists: true
  end
end
