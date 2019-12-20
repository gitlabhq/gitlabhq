# frozen_string_literal: true

class AddFingerprintSha256ToKey < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def up
    add_column(:keys, :fingerprint_sha256, :binary)
  end

  def down
    remove_column(:keys, :fingerprint_sha256) if column_exists?(:keys, :fingerprint_sha256)
  end
end
