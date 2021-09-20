# frozen_string_literal: true

# Initialize the new `throttle_unauthenticated_api_*` columns with the current values
# from the `throttle_unauthenticated_*` columns, which will now only apply to web requests.
#
# The columns for the unauthenticated web rate limit will be renamed later
# in https://gitlab.com/gitlab-org/gitlab/-/issues/340031.
class InitializeThrottleUnauthenticatedApiColumns < ActiveRecord::Migration[6.1]
  class ApplicationSetting < ActiveRecord::Base
    self.table_name = :application_settings
  end

  def up
    ApplicationSetting.update_all(%q{
      throttle_unauthenticated_api_enabled = throttle_unauthenticated_enabled,
      throttle_unauthenticated_api_requests_per_period = throttle_unauthenticated_requests_per_period,
      throttle_unauthenticated_api_period_in_seconds = throttle_unauthenticated_period_in_seconds
    })
  end

  def down
  end
end
