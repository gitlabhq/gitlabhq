# frozen_string_literal: true

class RemoveNotNullConstraintFromSbomSourceFingerprint < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    change_column_null :sbom_sources, :fingerprint, true
  end
end
