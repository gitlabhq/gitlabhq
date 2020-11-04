# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateGeoBlobVerificationPrimaryWorkerSidekiqQueue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'geo:geo_blob_verification_primary', to: 'geo:geo_verification'
  end

  def down
    sidekiq_queue_migrate 'geo:geo_verification', to: 'geo:geo_blob_verification_primary'
  end
end
