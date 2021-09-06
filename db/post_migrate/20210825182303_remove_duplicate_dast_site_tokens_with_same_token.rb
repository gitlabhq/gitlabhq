# frozen_string_literal: true

class RemoveDuplicateDastSiteTokensWithSameToken < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_dast_site_token_on_token'

  # rubocop: disable Migration/AddIndex
  def up
    execute("WITH duplicate_tokens AS(
                  SELECT id, rank() OVER (PARTITION BY token ORDER BY id) r FROM dast_site_tokens
                )
                DELETE FROM dast_site_tokens c USING duplicate_tokens t
                WHERE c.id = t.id AND t.r > 1;")

    add_index :dast_site_tokens, :token, name: INDEX_NAME, unique: true
  end

  # rubocop: disable Migration/RemoveIndex
  def down
    remove_index :dast_site_tokens, :token, name: INDEX_NAME
  end
end
