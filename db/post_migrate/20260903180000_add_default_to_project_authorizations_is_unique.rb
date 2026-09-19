# frozen_string_literal: true

class AddDefaultToProjectAuthorizationsIsUnique < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    change_column_default :project_authorizations, :is_unique, from: nil, to: true
  end
end
