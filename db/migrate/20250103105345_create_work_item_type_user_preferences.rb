# frozen_string_literal: true

class CreateWorkItemTypeUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  UNIQUE_INDEX_NAME = 'uniq_preference_by_user_namespace_and_work_item_type'

  # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
  # the factory exist in spec/factories/work_items/user_preference.rb
  def change
    create_table :work_item_type_user_preferences do |t|
      t.timestamps_with_timezone null: false

      t.bigint :user_id, null: false
      t.bigint :namespace_id, null: false
      t.bigint :work_item_type_id
      t.text :sort, limit: 255

      t.index %i[user_id namespace_id work_item_type_id], name: UNIQUE_INDEX_NAME
    end
  end
  # rubocop:enable Migration/EnsureFactoryForTable
end
