# frozen_string_literal: true

class AddProtectedAttributeToPendingBuilds < ActiveRecord::Migration[6.1]
  def change
    add_column :ci_pending_builds, :protected, :boolean, null: false, default: false
  end
end
