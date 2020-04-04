# frozen_string_literal: true

class ConsumeRemainingLinkLfsObjectsProjectsJobs < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('LinkLfsObjectsProjects')
  end

  def down
    # no-op as there is no need to do anything if this gets rolled back
  end
end
