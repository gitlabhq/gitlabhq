# frozen_string_literal: true

class AddArtifactsToCiBuildNeed < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_build_needs, :artifacts,
                            :boolean,
                            default: true,
                            allow_null: false)
  end

  def down
    remove_column(:ci_build_needs, :artifacts)
  end
end
