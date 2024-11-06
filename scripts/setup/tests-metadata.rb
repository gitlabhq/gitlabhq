#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'

class TestsMetadata < Struct.new( # rubocop:disable Style/StructInheritance -- Otherwise we cannot define a nested constant
  :mode,
  :knapsack_report_path, :flaky_report_path, :fast_quarantine_path,
  :average_knapsack,
  keyword_init: true)

  FALLBACK_JSON = '{}'

  def main
    abort("Unknown mode: `#{mode}`. It must be `retrieve` or `update`.") unless
      mode == 'retrieve' || mode == 'update' || mode == 'verify'

    if mode == 'verify'
      verify
    else
      prepare_directories
      retrieve
      update if mode == 'update'
    end
  end

  private

  def verify
    verify_knapsack_report
    verify_flaky_report
    verify_fast_quarantine
    puts 'OK'
  end

  def verify_knapsack_report
    report = JSON.parse(File.read(knapsack_report_path))

    valid = report.is_a?(Hash) &&
      report.all? do |spec, duration|
        spec.is_a?(String) && duration.is_a?(Numeric)
      end

    valid || abort("#{knapsack_report_path} is not a valid Knapsack report")
  rescue JSON::ParserError
    abort("#{knapsack_report_path} is not valid JSON")
  end

  def verify_flaky_report
    # This requires activesupport
    require_relative '../../gems/gitlab-rspec_flaky/lib/gitlab/rspec_flaky/report'

    Gitlab::RspecFlaky::Report.load(flaky_report_path).flaky_examples.to_h
  rescue JSON::ParserError
    abort("#{flaky_report_path} is not valid JSON")
  end

  def verify_fast_quarantine
    require_relative '../../tooling/lib/tooling/fast_quarantine'

    fast_quarantine =
      Tooling::FastQuarantine.new(fast_quarantine_path: fast_quarantine_path)

    fast_quarantine.identifiers
  end

  def prepare_directories
    FileUtils.mkdir_p([
      File.dirname(knapsack_report_path),
      File.dirname(flaky_report_path),
      File.dirname(fast_quarantine_path)
    ])
  end

  def retrieve
    tasks = []

    tasks << async_curl_download_json(
      url: "https://gitlab-org.gitlab.io/gitlab/#{knapsack_report_path}",
      path: knapsack_report_path,
      fallback_content: FALLBACK_JSON
    )

    tasks << async_curl_download_json(
      url: "https://gitlab-org.gitlab.io/gitlab/#{flaky_report_path}",
      path: flaky_report_path,
      fallback_content: FALLBACK_JSON
    )

    tasks << async_curl_download(
      url: "https://gitlab-org.gitlab.io/quality/engineering-productivity/fast-quarantine/#{fast_quarantine_path}",
      path: fast_quarantine_path,
      fallback_content: ''
    )

    tasks.compact.each(&:join)
  end

  def update
    update_knapsack_report
    update_flaky_report
    # Prune flaky tests that weren't flaky in the last 7 days, *after* updating the flaky tests detected
    # in this pipeline, so that first_flaky_at for tests that are still flaky is maintained.
    prune_flaky_report
  end

  def update_knapsack_report
    new_reports = Dir["#{File.dirname(knapsack_report_path)}/rspec*.json"]

    if average_knapsack
      system_abort_if_failed(%W[
        scripts/pipeline/average_reports.rb
        -i #{knapsack_report_path}
        -n #{new_reports.join(',')}
      ])
    else
      system_abort_if_failed(%W[
        scripts/merge-reports
        #{knapsack_report_path}
        #{new_reports.join(' ')}
      ])
    end
  end

  def update_flaky_report
    new_reports = Dir["#{File.dirname(flaky_report_path)}/all_*.json"]

    system_abort_if_failed(%W[
      scripts/merge-reports
      #{flaky_report_path}
      #{new_reports.join(' ')}
    ])
  end

  def prune_flaky_report
    system_abort_if_failed(%W[
      scripts/flaky_examples/prune-old-flaky-examples
      #{flaky_report_path}
    ])
  end

  def async_curl_download_json(**args)
    async_curl_download(**args) do |content|
      JSON.parse(content)
    rescue JSON::ParserError
      false
    end
  end

  def async_curl_download(url:, path:, fallback_content:)
    if force_download? || !File.exist?(path) # rubocop:disable Style/GuardClause -- This is easier to read
      async do
        success = system(*%W[curl --fail --location -o #{path} #{url}])

        if success
          if block_given? # rubocop:disable Style/IfUnlessModifier -- This is easier to read
            yield(File.read(path)) || File.write(path, fallback_content)
          end
        else
          File.write(path, fallback_content)
        end
      end
    end
  end

  def force_download?
    mode == 'retrieve'
  end

  def system_abort_if_failed(command)
    system(*command) || abort("Command failed for: #{command.join(' ')}")
  end

  def async(&task)
    Thread.new(&task)
  end
end

if $PROGRAM_NAME == __FILE__
  TestsMetadata.new(
    mode: ARGV.first,
    knapsack_report_path: ENV['KNAPSACK_RSPEC_SUITE_REPORT_PATH'] ||
      'knapsack/report-master.json',
    flaky_report_path: ENV['FLAKY_RSPEC_SUITE_REPORT_PATH'] ||
      'rspec/flaky/report-suite.json',
    fast_quarantine_path: ENV['RSPEC_FAST_QUARANTINE_PATH'] ||
      'rspec/fast_quarantine-gitlab.txt',
    average_knapsack: ENV['AVERAGE_KNAPSACK_REPORT'] == 'true'
  ).main
end
