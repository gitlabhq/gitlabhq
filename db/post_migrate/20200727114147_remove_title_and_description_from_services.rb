# frozen_string_literal: true

class RemoveTitleAndDescriptionFromServices < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    remove_column :services, :title, :string
    remove_column :services, :description, :string, limit: 500
  end
end
