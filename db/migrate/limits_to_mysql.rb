# rubocop:disable all
class LimitsToMysql < ActiveRecord::Migration
  def up
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/

    change_column :merge_request_diffs, :st_commits, :text, limit: 2147483647
    change_column :merge_request_diffs, :st_diffs, :text, limit: 2147483647
    change_column :snippets, :content, :text, limit: 2147483647
    change_column :notes, :st_diff, :text, limit: 2147483647
    change_column :events, :data, :text, limit: 2147483647
    change_column :gpg_keys, :primary_keyid, :binary, limit: 20
    change_column :gpg_keys, :fingerprint, :binary, limit: 20
    change_column :gpg_signatures, :commit_sha, :binary, limit: 20
    change_column :gpg_signatures, :gpg_key_primary_keyid, :binary, limit: 20
  end
end
