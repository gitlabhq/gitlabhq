# frozen_string_literal: true

class DropUnwantedSequenceForProjectIdForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    drop_sequence(
      :project_compliance_framework_settings,
      :project_id,
      :project_compliance_framework_settings_project_id_seq
    )
  end

  def down
    # We don't want to restore the sequence as it was a design flaw
    # Having a sequence on a foreign key column is an incident waiting to happen.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/526909
  end
end
