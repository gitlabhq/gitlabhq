# frozen_string_literal: true

class RemoveRequirementsIgnoredColumns < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_785ae25b9d'
  NAME_INDEX = 'index_requirements_on_title_trigram'
  FOREIGN_KEY = 'fk_rails_33fed8aa4e'

  def up
    remove_column(:requirements, :created_at, if_exists: true)
    remove_column(:requirements, :updated_at, if_exists: true)
    remove_column(:requirements, :author_id, if_exists: true)
    remove_column(:requirements, :cached_markdown_version, if_exists: true)
    remove_column(:requirements, :state, if_exists: true)
    remove_column(:requirements, :title, if_exists: true)
    remove_column(:requirements, :title_html, if_exists: true)
    remove_column(:requirements, :description, if_exists: true)
    remove_column(:requirements, :description_html, if_exists: true)
  end

  def down
    add_column(:requirements, :created_at, :datetime_with_timezone, if_not_exists: true)
    add_column(:requirements, :updated_at, :datetime_with_timezone, if_not_exists: true)
    add_column(:requirements, :author_id, :integer, if_not_exists: true)
    add_column(:requirements, :cached_markdown_version, :integer, if_not_exists: true)
    add_column(:requirements, :state, :smallint, default: 1, if_not_exists: true)
    add_column(:requirements, :title, :string, limit: 255, if_not_exists: true)
    add_column(:requirements, :title_html, :text, if_not_exists: true)
    add_column(:requirements, :description, :text, if_not_exists: true)
    add_column(:requirements, :description_html, :text, if_not_exists: true)

    add_check_constraint(:requirements, "char_length(description) <= 10000", CONSTRAINT_NAME)

    add_concurrent_foreign_key(:requirements, :users, column: :author_id, name: FOREIGN_KEY, on_delete: :nullify)

    add_concurrent_index(:requirements, :created_at)
    add_concurrent_index(:requirements, :updated_at)
    add_concurrent_index(:requirements, :author_id)
    add_concurrent_index(:requirements, :state)
    add_concurrent_index(:requirements, :title, name: NAME_INDEX, using: :gin, opclass: { name: :gin_trgm_ops })
  end
end
