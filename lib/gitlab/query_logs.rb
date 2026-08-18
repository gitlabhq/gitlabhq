# frozen_string_literal: true

module Gitlab
  # Tag list for ActiveRecord::QueryLogs. See config/initializers/query_logs.rb.
  module QueryLogs
    # Resolving the calling line walks the call stack on every SQL query, so it
    # is only enabled in development and test. In CI the overhead is significant
    # at scale, so it is opt-in there via QUERY_LOG_LINE=true. Locally it
    # remains opt-out via QUERY_LOG_LINE=false.
    #
    # This deliberately does not reuse Rails' built-in :source_location tag: the
    # key name is kept as :line so the annotation stays identical to the one the
    # marginalia gem produced, and the handler below is much cheaper than
    # ActiveRecord::QueryLogs.query_source_location.
    #
    # QueryRecorder re-enables this tag for the duration of its block so that
    # source attribution keeps working when the tag is globally disabled.
    LINE_TAG = { line: ->(context) { Tags.line(context) } }.freeze

    def self.tags
      tags = [
        { application: Gitlab.process_name },
        { correlation_id: ->(context) { Tags.correlation_id(context) } },
        { jid: ->(context) { Tags.jid(context) } },
        { endpoint_id: ->(context) { Tags.endpoint_id(context) } },
        { db_config_database: ->(context) { Tags.db_config_database(context) } },
        { db_config_name: ->(context) { Tags.db_config_name(context) } },
        { console_hostname: ->(context) { Tags.console_hostname(context) } },
        { console_username: ->(context) { Tags.console_username(context) } }
      ]

      tags << LINE_TAG if line_enabled?
      tags
    end

    def self.line_enabled?
      return false unless Gitlab.dev_or_test_env?

      Gitlab::Utils.to_boolean(ENV['QUERY_LOG_LINE'], default: !Gitlab::Utils.to_boolean(ENV['CI']))
    end
  end
end
