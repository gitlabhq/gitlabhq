class AddRepositoryVerificationToProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :project_registry, :repository_verification_checksum, :string
    add_column :project_registry, :last_repository_verification_at, :datetime_with_timezone
    add_column :project_registry, :last_repository_verification_failed, :boolean, null: false, default: false
    add_column :project_registry, :last_repository_verification_failure, :string

    add_column :project_registry, :wiki_verification_checksum, :string
    add_column :project_registry, :last_wiki_verification_at, :datetime_with_timezone
    add_column :project_registry, :last_wiki_verification_failed, :boolean, null: false, default: false
    add_column :project_registry, :last_wiki_verification_failure, :string
  end
end
