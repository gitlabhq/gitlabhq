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
    #
    # The handlers below outlive code reloads in development: they are captured
    # once at boot, but Zeitwerk unloads this module tree on reload. Tags must
    # be fully qualified so each call resolves the currently loaded module.
    LINE_TAG = { line: ->(context) { ::Gitlab::QueryLogs::Tags.line(context) } }.freeze

    def self.tags
      tags = [
        { application: Gitlab.process_name },
        { correlation_id: ->(context) { ::Gitlab::QueryLogs::Tags.correlation_id(context) } },
        { jid: ->(context) { ::Gitlab::QueryLogs::Tags.jid(context) } },
        { endpoint_id: ->(context) { ::Gitlab::QueryLogs::Tags.endpoint_id(context) } },
        { db_config_database: ->(context) { ::Gitlab::QueryLogs::Tags.db_config_database(context) } },
        { db_config_name: ->(context) { ::Gitlab::QueryLogs::Tags.db_config_name(context) } },
        { console_hostname: ->(context) { ::Gitlab::QueryLogs::Tags.console_hostname(context) } },
        { console_username: ->(context) { ::Gitlab::QueryLogs::Tags.console_username(context) } }
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
