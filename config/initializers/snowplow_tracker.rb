# frozen_string_literal: true

# Gitlab.com uses Snowplow for identifying users and events.
# https://gitlab.com/gitlab-org/gitlab/issues/6329
#
# SnowplowTracker write log into STDERR
# https://github.com/snowplow/snowplow-ruby-tracker/blob/39fcfa2be793f2e25e73087a9700abc93f43b5e8/lib/snowplow-tracker/emitters.rb#L23
#     `LOGGER = Logger.new(STDERR)`
#
# In puma.rb, if `stdout_redirect` specify stderr, Puma will overwrite STDERR in:
# https://github.com/puma/puma/blob/b41205f5cacbc2ad0060472bdce68ba636f42175/lib/puma/runner.rb#L134
#    `STDERR.reopen stderr, (append ? "a" : "w")`
# As a result, SnowplowTracker will log into Puma stderr, when Puma enabled.
#
# By default, SnowplowTracker uses default log formatter.
# When enable Puma, SnowplowTracker log is expected to be JSON format, as part of puma_stderr.log.
# Hence overwrite ::SnowplowTracker::LOGGER.formatter to JSON formatter

if defined?(::Puma) && defined?(::SnowplowTracker::LOGGER)
  ::SnowplowTracker::LOGGER.formatter = proc do |severity, datetime, progname, msg|
    { severity: severity, timestamp: datetime.utc.iso8601(3), pid: $$, progname: progname, message: msg }.to_json << "\n"
  end
end
