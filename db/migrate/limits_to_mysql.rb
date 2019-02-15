class LimitsToMysql < ActiveRecord::Migration[4.2]
  def up
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/

    change_column :snippets, :content, :text, limit: 2147483647
    change_column :notes, :st_diff, :text, limit: 2147483647
  end
end
