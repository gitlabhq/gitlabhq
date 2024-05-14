# frozen_string_literal: true

Time.zone = Gitlab.config.gitlab.time_zone || Time.zone
# The default is normally set by Rails in the
# active_support.initialize_time_zone Railtie, but we need to set it
# here because the config settings aren't available until after that
# runs. We set the default to ensure multi-threaded servers have the
# right value.
Time.zone_default = Time.zone

# Time.zone format is '(GMT+00:00) UTC', which causes
# (TZInfo::InvalidTimezoneIdentifier) when accessed as
# ::ActiveSupport::TimeZone.find_tzinfo(::Rails.application.config.time_zone)
# by sentry-rails https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150621#note_1878079953
Rails.application.config.time_zone = Time.zone.name
