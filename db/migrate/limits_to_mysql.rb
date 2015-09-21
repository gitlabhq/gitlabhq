class LimitsToMysql < ActiveRecord::Migration
  def up
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/

    change_column :merge_request_diffs, :st_commits, :text, limit: 2147483647
    change_column :merge_request_diffs, :st_diffs, :text, limit: 2147483647
    change_column :snippets, :content, :text, limit: 2147483647
    change_column :notes, :st_diff, :text, limit: 2147483647

    # CI
    change_column :ci_builds, :trace, :text, limit: 1073741823
    change_column :ci_commits, :push_data, :text, limit: 16777215
  end
end
