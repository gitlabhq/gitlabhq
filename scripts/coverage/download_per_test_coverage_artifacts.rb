#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

require_relative 'per_test_coverage_artifact_downloader'

# CLI wrapper around PerTestCoverageArtifactDownloader: matches jobs by regex
# in the triggered child pipeline, or in --pipeline-id's pipeline if given.
# The export jobs in `.gitlab/ci/coverage.gitlab-ci.yml` then feed the
# unpacked NDJSON / JSON files into the gem's `--per-test-coverage` flag.

options = { pattern: nil, output_dir: '.', process_command: nil, output_glob: nil, batch_size: 1,
            target_pipeline_id: nil }

OptionParser.new do |opts|
  opts.banner = 'Usage: download_per_test_coverage_artifacts.rb -p REGEX [-o PATH]'

  opts.on('-p', '--pattern REGEX', String,
    'Job-name regex matched against the target pipeline jobs (e.g. ' \
      '"^rspec(-ee)? .+ per-test-coverage( [0-9]+/[0-9]+)?$").') do |value|
    options[:pattern] = Regexp.new(value)
  end

  opts.on('--pipeline-id ID', String,
    'Pipeline to search for matching jobs (default: the child pipeline ' \
      "triggered by the '#{PerTestCoverageArtifactDownloader::BRIDGE_NAME}' bridge " \
      'in the current pipeline).') do |value|
    options[:target_pipeline_id] = value
  end

  opts.on('-o', '--output-dir PATH', String,
    "Directory to extract artifacts into (default: #{options[:output_dir]}).") do |value|
    options[:output_dir] = value
  end

  opts.on('--process-command CMD', String,
    'Shell command run on each downloaded batch before the next batch is ' \
      'fetched (e.g. the test-coverage insert). Enables streaming so disk ' \
      'stays bounded to one batch.') do |value|
    options[:process_command] = value
  end

  opts.on('--output-glob GLOB', String,
    'Glob of files to delete after each batch is processed (e.g. ' \
      '"tmp/per-test-coverage-rspec-*.ndjson"). Required with --process-command.') do |value|
    options[:output_glob] = value
  end

  opts.on('--batch-size N', Integer,
    "Shards to download before running --process-command (default: #{options[:batch_size]}).") do |value|
    options[:batch_size] = value
  end

  opts.on('-h', '--help', 'Print this help and exit') do
    puts opts
    exit
  end
end.parse!

abort "Missing required --pattern. Run with --help for usage." unless options[:pattern]

exit PerTestCoverageArtifactDownloader.new(
  job_name_pattern: options[:pattern],
  output_dir: options[:output_dir],
  process_command: options[:process_command],
  output_glob: options[:output_glob],
  batch_size: options[:batch_size],
  target_pipeline_id: options[:target_pipeline_id]
).run
