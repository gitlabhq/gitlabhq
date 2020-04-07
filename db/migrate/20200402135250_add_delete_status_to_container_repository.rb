# frozen_string_literal: true

class AddDeleteStatusToContainerRepository < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column(:container_repositories, :status, :integer, limit: 2)
  end

  def down
    remove_column(:container_repositories, :status)
  end
end
