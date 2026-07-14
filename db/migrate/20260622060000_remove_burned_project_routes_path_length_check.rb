# frozen_string_literal: true

# Drops the 255-char CHECK constraint on burned_project_routes.path.
#
# The constraint was added on the assumption that Route#path's
# `length: { within: 1..255 }` validation was an effective ceiling for
# routes.path. In practice that validation is bypassed by
# Routes::RenameDescendantsService#upsert_all (descendant route rewrites
# on parent-group rename or mark-for-deletion) and by legacy rows that
# pre-date the validation.
#
# Because Route#burn_vacated_project_path runs in an after_update
# callback inside the rename/delete transaction, a CHECK violation on
# the burn write rolls back the user-facing operation. Dropping the
# constraint restores burn protection for the realistic path-length
# band; the Postgres btree key limit (~2700 bytes) becomes the
# effective ceiling on the supporting unique index.
class RemoveBurnedProjectRoutesPathLengthCheck < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  TABLE_NAME = :burned_project_routes
  CONSTRAINT_NAME = 'check_7e5d3f66e0'

  def up
    remove_check_constraint TABLE_NAME, CONSTRAINT_NAME
  end

  def down
    add_check_constraint TABLE_NAME, 'char_length(path) <= 255', CONSTRAINT_NAME
  end
end
