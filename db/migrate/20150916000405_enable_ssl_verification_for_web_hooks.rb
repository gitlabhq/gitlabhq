class EnableSslVerificationForWebHooks < ActiveRecord::Migration
  def up
    execute("UPDATE web_hooks SET enable_ssl_verification = true")
  end

  def down
  end
end
