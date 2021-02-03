# frozen_string_literal: true

class AddDefaultProjectsHasExternalWiki < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default(:projects, :has_external_wiki, from: nil, to: false)
    end
  end

  def down
    with_lock_retries do
      change_column_default(:projects, :has_external_wiki, from: false, to: nil)
    end
  end
end
