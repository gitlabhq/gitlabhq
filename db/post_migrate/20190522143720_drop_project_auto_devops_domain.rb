# frozen_string_literal: true

class DropProjectAutoDevopsDomain < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :project_auto_devops, :domain, :string
  end
end
