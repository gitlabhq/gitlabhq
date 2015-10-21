class CiLimitsToMysql < ActiveRecord::Migration
  def change
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/

    # CI
    change_column :ci_builds, :trace, :text, limit: 1073741823
    change_column :ci_commits, :push_data, :text, limit: 16777215
  end
end
