# frozen_string_literal: true

class MigrateCreateCommitSignatureWorkerSidekiqQueue < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'create_gpg_signature', to: 'create_commit_signature'
  end

  def down
    sidekiq_queue_migrate 'create_commit_signature', to: 'create_gpg_signature'
  end
end
