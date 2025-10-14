# frozen_string_literal: true

class CreateTagGpgSignatures < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    create_table :tag_gpg_signatures do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in spec/factories/repositories/tags/gpg_signatures.rb
      t.bigint :project_id, null: false
      t.bigint :gpg_key_id, index: true
      t.bigint :gpg_key_subkey_id, index: true
      t.integer :verification_status, null: false, default: 0, limit: 2
      t.binary :object_name, null: false
      t.binary :gpg_key_primary_keyid, null: false
      t.text :gpg_key_user_name, limit: 255
      t.text :gpg_key_user_email, limit: 255

      t.timestamps_with_timezone null: false
    end
  end
end
