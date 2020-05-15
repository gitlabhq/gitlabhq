# frozen_string_literal: true

class AddVersionToFeatureFlagsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  FEATURE_FLAG_LEGACY_VERSION = 1

  def up
    # The operations_feature_flags table is small enough that we can disable this cop.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25552#note_291202882
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default(:operations_feature_flags, :version, :smallint, default: FEATURE_FLAG_LEGACY_VERSION, allow_null: false)
    # rubocop:enable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:operations_feature_flags, :version)
  end
end
