# frozen_string_literal: true

# Gitlab.com uses Snowplow for identifying users and events.
# https://gitlab.com/gitlab-org/gitlab/issues/6329
#
# SnowplowTracker writes logs to STDERR:
# https://github.com/snowplow/snowplow-ruby-tracker/blob/39fcfa2be793f2e25e73087a9700abc93f43b5e8/lib/snowplow-tracker/emitters.rb#L23
if defined?(::SnowplowTracker::LOGGER)
  # This squelches the output of the logger since it doesn't really
  # provide useful information.
  # https://github.com/snowplow/snowplow-ruby-tracker/pull/109
  # would make it possible to configure this logger directly.
  ::SnowplowTracker::LOGGER.level = Logger::FATAL
end
