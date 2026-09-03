# frozen_string_literal: true

class CreateInstanceSshCertificates < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :instance_ssh_certificates do |t|
      t.timestamps_with_timezone null: false
      t.binary :fingerprint, null: false, index: { unique: true }
      t.text :title, null: false, limit: 255
      # rubocop:disable Migration/PreventLargeBlobInDatabase -- matches the model's length validation; an SSH CA public key is a single bounded credential, not blob content
      t.text :key, null: false, limit: 5000
      # rubocop:enable Migration/PreventLargeBlobInDatabase
    end
  end
end
