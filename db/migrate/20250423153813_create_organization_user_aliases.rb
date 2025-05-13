# frozen_string_literal: true

class CreateOrganizationUserAliases < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def change
    create_table :organization_user_aliases do |t| # rubocop:disable Lint/RedundantCopDisableDirective, Migration/EnsureFactoryForTable -- factory file sometimes incorrectly detected by rubocop as organizations_organization_user_aliases
      t.belongs_to :organization, null: false, index: false
      t.belongs_to :user, null: false

      # rubocop:disable Migration/PreventStrings -- these columns' type should be the same as User#username and User#name
      t.string :username, null: false
      t.string :display_name
      # rubocop:enable Migration/PreventStrings

      t.timestamps_with_timezone null: false

      t.index [:organization_id, :user_id], unique: true,
        name: :unique_organization_user_alias_organization_id_user_id
      t.index [:organization_id, :username], unique: true,
        name: :unique_organization_user_alias_organization_id_username
    end
  end
end
