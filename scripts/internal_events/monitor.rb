#!/usr/bin/env ruby
# frozen_string_literal: true

# Internal Events Tracking Monitor
#
# This script provides real-time monitoring of Internal Events Tracking-related metrics and Snowplow events.
#
# Usage:
#   Run this script in your terminal with specific event names as command-line arguments. It will continuously
#   display relevant metrics and Snowplow events associated with the provided event names.
#
# Example:
#   To monitor events 'g_edit_by_web_ide' and 'g_edit_by_sfe', execute:
#   ```
#   bin/rails runner scripts/internal_events/monitor.rb g_edit_by_web_ide g_edit_by_sfe
#   ```
#
# Exiting:
#   - To exit the script, press Ctrl+C.
#

unless defined?(Rails)
  puts <<~TEXT

    Error! The Internal Events Tracking Monitor could not access the Rails context!

      Ensure GDK is running, then run:

      bin/rails runner scripts/internal_events/monitor.rb #{ARGV.any? ? ARGV.join(' ') : '<events-to-monitor>'}

  TEXT

  exit! 1
end

unless ARGV.any?
  puts <<~TEXT

    Error! The Internal Events Tracking Monitor requires events to be specified.

      For example, to monitor events g_edit_by_web_ide and g_edit_by_sfe, run:

      bin/rails runner scripts/internal_events/monitor.rb g_edit_by_web_ide g_edit_by_sfe

  TEXT

  exit! 1
end

require 'terminal-table'
require 'net/http'

require_relative './server'
require_relative '../../spec/support/helpers/service_ping_helpers'

Gitlab::Usage::TimeFrame.prepend(ServicePingHelpers::CurrentTimeFrame)

def metric_definitions_from_args
  args = ARGV
  Gitlab::Usage::MetricDefinition.all.select do |metric|
    metric.available? && args.any? { |arg| metric.events.key?(arg) }
  end
end

def red(text)
  @pastel ||= Pastel.new

  @pastel.red(text)
end

def current_timestamp
  (Time.now.to_f * 1000).to_i
end

def snowplow_data
  url = Gitlab::Tracking::Destinations::SnowplowMicro.new.uri.merge('/micro/good')
  response = Net::HTTP.get_response(url)

  return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

  raise "Request failed: #{response.code}"
end

def extract_standard_context(event)
  event['event']['contexts']['data'].each do |context|
    next unless context['schema'].start_with?('iglu:com.gitlab/gitlab_standard/jsonschema')

    return {
      user_id: context["data"]["user_id"],
      namespace_id: context["data"]["namespace_id"],
      project_id: context["data"]["project_id"],
      plan: context["data"]["plan"],
      extra: context["data"]["extra"]
    }
  end
  {}
end

def generate_snowplow_table
  events = snowplow_data.select { |d| ARGV.include?(d["event"]["se_action"]) }
            .filter { |e| e['rawEvent']['parameters']['dtm'].to_i > @min_timestamp }

  @initial_max_timestamp ||= events.map { |e| e['rawEvent']['parameters']['dtm'].to_i }.max || 0

  rows = []
  rows << [
    'Event Name',
    'Collector Timestamp',
    'Category',
    'user_id',
    'namespace_id',
    'project_id',
    'plan',
    'Label',
    'Property',
    'Value',
    'Extra'
  ]

  rows << :separator

  events.each do |event|
    standard_context = extract_standard_context(event)

    row = [
      event['event']['se_action'],
      event['event']['collector_tstamp'],
      event['event']['se_category'],
      standard_context[:user_id],
      standard_context[:namespace_id],
      standard_context[:project_id],
      standard_context[:plan],
      event['event']['se_label'],
      event['event']['se_property'],
      event['event']['se_value'],
      standard_context[:extra]
    ]

    row.map! { |value| red(value) } if event['rawEvent']['parameters']['dtm'].to_i > @initial_max_timestamp

    rows << row
  end

  Terminal::Table.new(
    title: 'SNOWPLOW EVENTS',
    rows: rows
  )
end

def relevant_events_from_args(metric_definition)
  metric_definition.events.keys.intersection(ARGV).sort
end

def generate_metrics_table
  metric_definitions = metric_definitions_from_args
  rows = []
  rows << ['Key Path', 'Monitored Events', 'Instrumentation Class', 'Initial Value', 'Current Value']
  rows << :separator

  @initial_values ||= {}

  metric_definitions.sort_by(&:key).each do |definition|
    metric = Gitlab::Usage::Metric.new(definition)
    value = metric.send(:instrumentation_object).value # rubocop:disable GitlabSecurity/PublicSend
    @initial_values[definition.key] ||= value

    initial_value = @initial_values[definition.key]

    value = red(value) if initial_value != value

    rows << [
      definition.key,
      relevant_events_from_args(definition).join(', '),
      definition.instrumentation_class,
      initial_value,
      value
    ]
  end

  Terminal::Table.new(
    title: 'RELEVANT METRICS',
    rows: rows
  )
end

def render_screen(paused)
  metrics_table = generate_metrics_table
  events_table = generate_snowplow_table

  print TTY::Cursor.clear_screen
  print TTY::Cursor.move_to(0, 0)

  puts "Updated at #{Time.current} #{'[PAUSED]' if paused}"
  puts "Monitored events: #{ARGV.join(', ')}"
  puts

  puts metrics_table
  puts events_table

  puts
  puts "Press \"p\" to toggle refresh. (It makes it easier to select and copy the tables)"
  puts "Press \"r\" to reset without exiting the monitor"
  puts "Press \"q\" to quit"
end

server = nil
@min_timestamp = current_timestamp

begin
  snowplow_data
rescue Errno::ECONNREFUSED
  # Start the mock server if Snowplow Micro is not running
  server = Thread.start { Server.new.start }
end

reader = TTY::Reader.new
paused = false

begin
  loop do
    case reader.read_keypress(nonblock: true)
    when 'p'
      paused = !paused
      render_screen(paused)
    when 'r'
      @min_timestamp = current_timestamp
      @initial_values = {}
    when 'q'
      server&.exit
      break
    end

    render_screen(paused) unless paused

    sleep 1
  end
rescue Interrupt
  server&.exit
rescue Errno::ECONNREFUSED
  # Ignore this error, caused by the server being killed before the loop due to working on a child thread
end
