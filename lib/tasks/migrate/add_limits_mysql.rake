desc "GITLAB | Add limits to strings in mysql database"
task add_limits_mysql: :environment do
  puts "Adding limits to schema.rb for mysql"
  LimitsToMysql.new.up
end

class LimitsToMysql < ActiveRecord::Migration
  def up
    change_column :merge_request_diffs, :st_commits, :text, limit: 2147483647
    change_column :merge_request_diffs, :st_diffs, :text, limit: 2147483647
    change_column :snippets, :content, :text, limit: 2147483647
  end
end
