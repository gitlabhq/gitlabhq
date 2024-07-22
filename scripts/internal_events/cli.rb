#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a metric/event files in the correct locations.

require 'tty-prompt'
require 'net/http'
require 'yaml'
require 'json_schemer'

require_relative './cli/helpers'
require_relative './cli/usage_viewer'
require_relative './cli/metric_definer'
require_relative './cli/event_definer'
require_relative './cli/global_state'
require_relative './cli/metric'
require_relative './cli/event'
require_relative './cli/text'

class Cli
  include ::InternalEventsCli::Helpers

  attr_reader :cli

  def initialize(cli)
    @cli = cli
  end

  def run
    cli.say InternalEventsCli::Text::FEEDBACK_NOTICE
    cli.say InternalEventsCli::Text::CLI_INSTRUCTIONS

    task = cli.select("What would you like to do?", **select_opts) do |menu|
      menu.enum "."

      menu.choice "New Event -- track when a specific scenario occurs on gitlab instances\n     " \
                  "ex) a user applies a label to an issue", :new_event
      menu.choice "New Metric -- track the count of existing events over time\n     " \
                  "ex) count unique users who assign labels to issues per month", :new_metric
      menu.choice 'View Usage -- look at code and testing examples for existing events & metrics', :view_usage
      menu.choice '...am I in the right place?', :help_decide
    end

    case task
    when :new_event
      InternalEventsCli::EventDefiner.new(cli).run
    when :new_metric
      InternalEventsCli::MetricDefiner.new(cli).run
    when :view_usage
      InternalEventsCli::UsageViewer.new(cli).run
    when :help_decide
      help_decide
    end
  end

  private

  def help_decide
    return use_case_error unless goal_is_tracking_usage?
    return use_case_error unless usage_trackable_with_internal_events?

    event_already_tracked? ? proceed_to_metric_definition : proceed_to_event_definition
  end

  def goal_is_tracking_usage?
    new_page!

    cli.say format_info("First, let's check your objective.\n")

    cli.yes?('Are you trying to track customer usage of a GitLab feature?', **yes_no_opts)
  end

  def usage_trackable_with_internal_events?
    new_page!

    cli.say format_info("Excellent! Let's check that this tool will fit your needs.\n")
    cli.say InternalEventsCli::Text::EVENT_TRACKING_EXAMPLES

    cli.yes?(
      'Can usage for the feature be measured with a count of specific user actions or events? ' \
      'Or counting a set of events?', **yes_no_opts
    )
  end

  def event_already_tracked?
    new_page!

    cli.say format_info("Super! Let's figure out if the event is already tracked & usable.\n")
    cli.say InternalEventsCli::Text::EVENT_EXISTENCE_CHECK_INSTRUCTIONS

    cli.yes?('Is the event already tracked?', **yes_no_opts)
  end

  def use_case_error
    new_page!

    cli.error("Oh no! This probably isn't the tool you need!\n")
    cli.say InternalEventsCli::Text::ALTERNATE_RESOURCES_NOTICE
    cli.say InternalEventsCli::Text::FEEDBACK_NOTICE
  end

  def proceed_to_metric_definition
    new_page!

    cli.say format_info("Amazing! The next step is adding a new metric! (~8-15 min)\n")

    return not_ready_error('New Metric') unless cli.yes?(format_prompt('Ready to start?'))

    InternalEventsCli::MetricDefiner.new(cli).run
  end

  def proceed_to_event_definition
    new_page!

    cli.say format_info("Okay! The next step is adding a new event! (~5-10 min)\n")

    return not_ready_error('New Event') unless cli.yes?(format_prompt('Ready to start?'))

    InternalEventsCli::EventDefiner.new(cli).run
  end

  def not_ready_error(description)
    cli.say "\nNo problem! When you're ready, run the CLI & select '#{description}'\n"
    cli.say InternalEventsCli::Text::FEEDBACK_NOTICE
  end
end

class GitlabPrompt < SimpleDelegator
  def global
    @global ||= InternalEventsCli::GlobalState.new
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    prompt = GitlabPrompt.new(TTY::Prompt.new)

    Cli.new(prompt).run
  rescue Interrupt
    puts "\n"
  end
end

# vim: ft=ruby
