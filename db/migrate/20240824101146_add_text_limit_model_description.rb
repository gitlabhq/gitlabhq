# frozen_string_literal: true

class AddTextLimitModelDescription < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'

  def up
    model_constraint_name = check_constraint_name(:ml_models, :description, '10K')
    version_constraint_name = check_constraint_name(:ml_model_versions, :description, '10K')
    add_text_limit :ml_models, :description, 10_000, constraint_name: model_constraint_name
    add_text_limit :ml_model_versions, :description, 10_000, constraint_name: version_constraint_name
    remove_text_limit :ml_models, :description, constraint_name: 'check_d0c47d63b5'
    remove_text_limit :ml_model_versions, :description, constraint_name: 'check_caff7d000b'
  end

  def down
    # no-op: Danger of failing if there are records with smaller length
  end
end
