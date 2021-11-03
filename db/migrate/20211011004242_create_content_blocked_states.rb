# frozen_string_literal: true

class CreateContentBlockedStates < Gitlab::Database::Migration[1.0]
  def change
    create_table :content_blocked_states, comment: 'JiHu-specific table' do |t|
      t.timestamps_with_timezone null: false
      t.binary :commit_sha, null: false
      t.binary :blob_sha, null: false
      t.text :path, null: false, limit: 2048
      t.text :container_identifier, null: false, limit: 255

      t.index [:container_identifier, :commit_sha, :path], name: 'index_content_blocked_states_on_container_id_commit_sha_path', unique: true
    end
  end
end
