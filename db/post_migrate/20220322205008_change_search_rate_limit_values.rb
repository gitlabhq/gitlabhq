# frozen_string_literal: true

class ChangeSearchRateLimitValues < Gitlab::Database::Migration[1.0]
  def up
    # Change search_rate_limits to a more reasonable value
    # as long as they are still using the default values.
    #
    # The reason why `search_rate_limit` could be either 30 or 60
    # is because its value was ported over from the now deprecated
    # `user_email_lookup_limit` which had a default value of 60.
    execute("update application_settings set search_rate_limit=300 where search_rate_limit IN (30,60)")
    execute("update application_settings set search_rate_limit_unauthenticated=100 where search_rate_limit_unauthenticated = 10")
  end

  def down
    # noop. Because this  migration is updating values, it is not reversible.
  end
end
