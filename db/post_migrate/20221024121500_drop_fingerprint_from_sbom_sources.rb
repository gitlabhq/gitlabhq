# frozen_string_literal: true

class DropFingerprintFromSbomSources < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    remove_column :sbom_sources, :fingerprint, :bytea
  end
end
