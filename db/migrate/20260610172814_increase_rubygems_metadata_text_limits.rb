# frozen_string_literal: true

class IncreaseRubygemsMetadataTextLimits < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  TABLE = :packages_rubygems_metadata

  # These gemspec fields are stored as JSON-serialized arrays (file lists,
  # require paths, executables, etc.) and routinely exceed the original 255
  # limit, which caused PG::CheckViolation on valid gems. We raise them to
  # match the existing `metadata` column limit (30000) on this same table.
  NEW_LIMIT = 30_000

  COLUMNS = %i[
    files
    extensions
    executables
    extra_rdoc_files
    require_paths
    rdoc_options
    requirements
    licenses
  ].freeze

  def up
    # Add the larger limit under a new constraint name, then drop the old 255
    # constraint, per the documented "increasing a text limit" procedure.
    #
    # rubocop:disable Migration/PreventLargeBlobInDatabase -- These columns hold
    # JSON-serialized gemspec arrays that legitimately exceed 4096 characters
    # (for example, a gem's full file list). 30000 matches the existing
    # metadata column on this table. See https://gitlab.com/gitlab-org/gitlab/-/work_items/333607.
    add_text_limit TABLE, :files, NEW_LIMIT, constraint_name: new_constraint_name(:files)
    add_text_limit TABLE, :extensions, NEW_LIMIT, constraint_name: new_constraint_name(:extensions)
    add_text_limit TABLE, :executables, NEW_LIMIT, constraint_name: new_constraint_name(:executables)
    add_text_limit TABLE, :extra_rdoc_files, NEW_LIMIT, constraint_name: new_constraint_name(:extra_rdoc_files)
    add_text_limit TABLE, :require_paths, NEW_LIMIT, constraint_name: new_constraint_name(:require_paths)
    add_text_limit TABLE, :rdoc_options, NEW_LIMIT, constraint_name: new_constraint_name(:rdoc_options)
    add_text_limit TABLE, :requirements, NEW_LIMIT, constraint_name: new_constraint_name(:requirements)
    add_text_limit TABLE, :licenses, NEW_LIMIT, constraint_name: new_constraint_name(:licenses)
    # rubocop:enable Migration/PreventLargeBlobInDatabase

    COLUMNS.each { |column| remove_text_limit TABLE, column }
  end

  def down
    # no-op: re-adding the original 255 limit would fail for records that have
    # already stored larger values under the new limit.
  end

  private

  def new_constraint_name(column)
    check_constraint_name(TABLE, column, "max_length_#{NEW_LIMIT}")
  end
end
