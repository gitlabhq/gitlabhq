class AddAcmeChallengeColumnsForPagesDomain < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :pages_domains, :acme_challenge_token, :text
    add_column :pages_domains, :acme_challenge_response, :text
  end
end
