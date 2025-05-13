# frozen_string_literal: true

class ChangeAiTroubleshootJobEventsProjectFk < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.0'

  def up
    # NOP due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19723
    # This already ran on staging.
  end

  def down
    # NOP due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19723
    # This already ran on staging.
  end
end
