# frozen_string_literal: true

class ScheduleExpireOAuthTokens < Gitlab::Database::Migration[2.0]
  def up
    # reschedulled with db/post_migrate/20220513043344_reschedule_expire_o_auth_tokens.rb
  end

  def down
    # reschedulled with db/post_migrate/20220513043344_reschedule_expire_o_auth_tokens.rb
  end
end
