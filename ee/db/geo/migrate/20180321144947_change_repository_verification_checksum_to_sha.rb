class ChangeRepositoryVerificationChecksumToSha < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column :project_registry, :repository_verification_checksum_sha, :binary
    add_column :project_registry, :wiki_verification_checksum_sha, :binary
  end

  def down
    remove_column :project_registry, :repository_verification_checksum_sha
    remove_column :project_registry, :wiki_verification_checksum_sha
  end
end
