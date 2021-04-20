# frozen_string_literal: true

class UpdateRubygemsMetadataMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_text_limit :packages_rubygems_metadata, :metadata
    add_text_limit :packages_rubygems_metadata, :metadata, 30000
  end

  def down
    remove_text_limit :packages_rubygems_metadata, :metadata
    add_text_limit :packages_rubygems_metadata, :metadata, 255, validate: false
  end
end
