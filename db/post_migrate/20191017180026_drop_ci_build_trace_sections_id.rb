# frozen_string_literal: true

class DropCiBuildTraceSectionsId < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    ##
    # This column has already been ignored since 12.4
    # See https://gitlab.com/gitlab-org/gitlab/issues/32569
    remove_column :ci_build_trace_sections, :id
  end

  def down
    ##
    # We don't backfill serial ids as it's not used in application code
    # and quite expensive process.
    add_column :ci_build_trace_sections, :id, :bigint
  end
end
