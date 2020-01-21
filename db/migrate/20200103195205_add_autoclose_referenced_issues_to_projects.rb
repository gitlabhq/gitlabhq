# frozen_string_literal: true

class AddAutocloseReferencedIssuesToProjects < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :autoclose_referenced_issues, :boolean
  end
end
