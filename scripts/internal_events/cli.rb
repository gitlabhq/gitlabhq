#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a metric/event files in the correct locations.

require 'tty-prompt'
require 'net/http'
require 'yaml'
require 'json_schemer'
require 'delegate'

require_relative './cli/helpers'
require_relative './cli/flows/usage_viewer'
require_relative './cli/flows/metric_definer'
require_relative './cli/flows/event_definer'
require_relative './cli/flows/flow_advisor'
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
      InternalEventsCli::Flows::EventDefiner.new(cli).run
    when :new_metric
      InternalEventsCli::Flows::MetricDefiner.new(cli).run
    when :view_usage
      InternalEventsCli::Flows::UsageViewer.new(cli).run
    when :help_decide
      InternalEventsCli::Flows::FlowAdvisor.new(cli).run
    end
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
