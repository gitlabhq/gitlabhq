class AddPagesDomainEnabledUntil < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :pages_domains, :enabled_until, :datetime_with_timezone
  end
end
