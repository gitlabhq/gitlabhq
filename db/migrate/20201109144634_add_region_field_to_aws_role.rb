# frozen_string_literal: true

class AddRegionFieldToAwsRole < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:aws_roles, :region)
      add_column :aws_roles, :region, :text
    end

    add_text_limit :aws_roles, :region, 255
  end

  def down
    remove_column :aws_roles, :region
  end
end
