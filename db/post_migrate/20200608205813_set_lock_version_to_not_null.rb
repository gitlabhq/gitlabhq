# frozen_string_literal: true

class SetLockVersionToNotNull < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  MODELS = [Epic, MergeRequest, Issue, Ci::Stage, Ci::Build, Ci::Pipeline].freeze

  disable_ddl_transaction!

  def up
    MODELS.each do |model|
      model.where(lock_version: nil).update_all(lock_version: 0)
    end
  end

  def down
    # Nothing to do...
  end
end
