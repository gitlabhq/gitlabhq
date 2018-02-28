# rubocop:disable all
class LimitsToMysql < ActiveRecord::Migration
  def up
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/

    # These columns were removed in 10.3, but this is called from two places:
    # 1. A migration run after they were added, but before they were removed.
    # 2. A rake task which can be run at any time.
    #
    # Because of item 2, we need these checks.
    if column_exists?(:merge_request_diffs, :st_commits)
      change_column :merge_request_diffs, :st_commits, :text, limit: 2147483647
    end

    if column_exists?(:merge_request_diffs, :st_diffs)
      change_column :merge_request_diffs, :st_diffs, :text, limit: 2147483647
    end

    change_column :snippets, :content, :text, limit: 2147483647
    change_column :notes, :st_diff, :text, limit: 2147483647
  end
end
