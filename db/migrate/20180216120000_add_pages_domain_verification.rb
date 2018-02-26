class AddPagesDomainVerification < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :pages_domains, :verified_at, :datetime_with_timezone
    add_column :pages_domains, :verification_code, :string
  end
end
