#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a metric/event files in the correct locations.

require 'tty-prompt'
require 'net/http'
require 'yaml'
require 'json_schemer'
require 'delegate'

require_relative './cli/helpers'
require_relative './cli/flows/event_definer'
require_relative './cli/flows/flow_advisor'
require_relative './cli/flows/metric_definer'
require_relative './cli/flows/usage_viewer'
require_relative './cli/global_state'
require_relative './cli/time_framed_key_path'
require_relative './cli/metric'
require_relative './cli/event'

class Cli
  include ::InternalEventsCli::Helpers

  attr_reader :cli

  def initialize(cli)
    @cli = cli
  end

  def run
    cli.say feedback_notice
    cli.say instructions

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

  def instructions
    cli.say <<~TEXT.freeze
      #{format_info('INSTRUCTIONS:')}
      To start tracking usage of a feature...

        1) Define event (using CLI)
        2) Trigger event (from code)
        3) Define metric (using CLI)
        4) View data in Tableau (after merge & deploy)

      This CLI will help you create the correct defintion files, then provide code examples for instrumentation and testing.

      Learn more: https://docs.gitlab.com/ee/development/internal_analytics/#fundamental-concepts

    TEXT
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
