# rubocop:disable all
require Rails.root.join('lib/gitlab/database/migration_helpers.rb')

class LimitsToMysql < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def up
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/

    change_column :merge_request_diffs, :st_commits, :text, limit: 2147483647
    change_column :merge_request_diffs, :st_diffs, :text, limit: 2147483647
    change_column :snippets, :content, :text, limit: 2147483647
    change_column :notes, :st_diff, :text, limit: 2147483647
    change_column :events, :data, :text, limit: 2147483647

    [
      [:gpg_keys, :primary_keyid],
      [:gpg_signatures, :commit_sha],
      [:gpg_signatures, :gpg_key_primary_keyid]
    ].each do |table_name, column_name|
      remove_index table_name, column_name if index_exists?(table_name, column_name)
      add_concurrent_index table_name, column_name, length: 20
    end
  end
end
