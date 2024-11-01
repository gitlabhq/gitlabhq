# frozen_string_literal: true

# Blocks of text rendered in CLI
module InternalEventsCli
  module Text
    module MetricDefiner
      extend Helpers

      DATABASE_METRIC_NOTICE = <<~TEXT

        For right now, this script can only define metrics for internal events.

        For more info on instrumenting database-backed metrics, see https://docs.gitlab.com/ee/development/internal_analytics/metrics/metrics_instrumentation.html
      TEXT

      ALL_METRICS_EXIST_NOTICE = <<~TEXT

        Looks like the potential metrics for this event either already exist or are unsupported.

        Check out https://metrics.gitlab.com/ for improved event/metric search capabilities.
      TEXT

      DESCRIPTION_INTRO = <<~TEXT.freeze
        #{format_info('METRIC DESCRIPTION')}
        Describes which occurrences of an event are tracked in the metric and how they're grouped.

        The description field is critical for helping others find & reuse this event. This will be used by Engineering, Product, Data team, Support -- and also GitLab customers directly. Be specific and explicit.

        #{format_info('GOOD EXAMPLES:')}
        - Total count of analytics dashboard list views
        - Weekly count of unique users who viewed the analytics dashboard list
        - Monthly count of unique projects where the analytics dashboard list was viewed
        - Total count of issue updates

        #{format_info('SELECTED EVENT(S):')}
      TEXT

      DESCRIPTION_HELP = <<~TEXT.freeze
        #{format_warning('Required. 10+ words likely, but length may vary.')}

          An event description can often be rearranged to work as a metric description.

          ex) Event description: A merge request was created
              Metric description: Total count of merge requests created
              Metric description: Weekly count of unqiue users who created merge requests

          Look at the event descriptions above to get ideas!
      TEXT

      NAME_FILTER_HELP = <<~TEXT.freeze
        #{format_warning('Required. Max %{count} characters. Only lowercase/numbers/underscores allowed.')}

        Metrics with filters must manually define this portion of their key path.

        Auto-generated key paths for metrics filters results in long & confusing naming. By defining them manually, clarity and discoverability should be better.
      TEXT

      NAME_CONFLICT_HELP = <<~TEXT.freeze
        #{format_warning('Required. Max %{count} characters. Only lowercase/numbers/underscores allowed.')}

        Conflict! A metric with the same name already exists: %{name}
      TEXT

      NAME_LENGTH_HELP = <<~TEXT.freeze
        #{format_warning('Required. Max %{count} characters. Only lowercase/numbers/underscores allowed.')}

        Filenames cannot exceed 100 characters. The key path (ID) is not restricted, but keeping them aligned is recommended.

        If needed, you can modify the key path and filename further after saving.
      TEXT

      NAME_REQUIREMENT_REASONS = {
        filters: {
          text: 'Metrics using filters are too complex for default naming.',
          help: NAME_FILTER_HELP
        },
        length: {
          text: 'The default filename will be too long.',
          help: NAME_LENGTH_HELP
        },
        conflict: {
          text: 'The default key path is already in use.',
          help: NAME_CONFLICT_HELP
        }
      }.freeze

      NAME_ERROR = <<~TEXT.freeze
        #{format_warning('Input is invalid. Max %{count} characters. Only lowercase/numbers/underscores allowed. Ensure this key path (ID) is not already in use.')}
      TEXT
    end
  end
end
