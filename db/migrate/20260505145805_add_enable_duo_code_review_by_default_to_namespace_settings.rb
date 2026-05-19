# frozen_string_literal: true

class AddEnableDuoCodeReviewByDefaultToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :namespace_settings, :enable_duo_code_review_by_default, :smallint, null: false, default: 0
  end
end
