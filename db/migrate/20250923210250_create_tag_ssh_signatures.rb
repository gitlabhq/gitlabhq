# frozen_string_literal: true

class CreateTagSshSignatures < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    create_table :tag_ssh_signatures do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in spec/factories/repositories/tags/ssh_signatures.rb
      t.bigint :project_id, null: false
      t.bigint :key_id, index: true
      t.integer :verification_status, null: false, default: 0, limit: 2
      t.binary :object_name, null: false
      t.binary :key_fingerprint_sha256

      t.timestamps_with_timezone null: false
    end
  end
end
