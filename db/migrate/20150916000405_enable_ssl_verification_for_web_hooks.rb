class EnableSslVerificationForWebHooks < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE web_hooks SET enable_ssl_verification = true")
  end

  def down
  end
end
