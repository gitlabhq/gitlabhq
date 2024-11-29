# frozen_string_literal: true

require_relative './helpers/cli_inputs'
require_relative './helpers/files'
require_relative './helpers/formatting'
require_relative './helpers/group_ownership'
require_relative './helpers/event_options'
require_relative './helpers/metric_options'
require_relative './helpers/service_ping_dashboards'

module InternalEventsCli
  module Helpers
    include CliInputs
    include Files
    include Formatting
    include GroupOwnership
    include EventOptions
    include MetricOptions
    include ServicePingDashboards

    MILESTONE = File.read('VERSION').strip.match(/(\d+\.\d+)/).captures.first
    NAME_REGEX = /\A[a-z0-9_]+\z/

    def new_page!(on_step: nil, steps: [])
      cli.say TTY::Cursor.clear_screen
      cli.say TTY::Cursor.move_to(0, 0)
      cli.say "#{progress_bar(on_step, steps)}\n" if on_step && steps&.any?
    end

    def feedback_notice
      format_heading <<~TEXT.chomp
        Thanks for using the Internal Events CLI!

        Please reach out with any feedback!
          About Internal Events: https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/internal/-/issues/687
          About CLI: https://gitlab.com/gitlab-org/gitlab/-/issues/434038
          In Slack: #g_analyze_analytics_instrumentation

        Let us know that you used the CLI! React with 👍 on the feedback issue or post in Slack!
      TEXT
    end
  end
end
