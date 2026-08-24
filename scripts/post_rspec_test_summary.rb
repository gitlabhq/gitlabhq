#!/usr/bin/env ruby
# frozen_string_literal: true

# Posts (or updates) an "RSpec Test Result Summary" comment on the current MR.
#
# Runs once per pipeline, from a single post-test job that collects the RSpec
# JSON reports of every rspec job via artifacts. It must stay the only writer:
# posting from each rspec job instead would race hundreds of jobs against one
# note and report whichever slice happened to finish last.
#
# Uses only Ruby stdlib (net/http, json, optparse) so no bundle install is
# required.
#
# Required env vars (standard CI variables):
#   PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE
#   CI_API_V4_URL
#   CI_PROJECT_ID
#   CI_MERGE_REQUEST_IID  (only set for merge-request pipelines)
#   CI_JOB_NAME, CI_JOB_URL
#   CI_PROJECT_DIR        (used to normalise absolute report paths)
#
# Actionability model (mirrors scripts/frontend/post_msw_test_summary.mjs):
#   - Aggregates every rspec job's report into one per-file map.
#   - Publishes a compact per-file baseline artifact (every pipeline, master included).
#   - Detects the spec files this MR adds/changes (via the MR diffs API).
#   - For each changed file that ran in this pipeline, diffs its runtime and
#     example count against the same file in the latest successful master run.
#   - Reports the runtime and example-count delta this MR introduces.
#
# There is deliberately no per-example budget or failing gate: RSpec example
# cost varies by orders of magnitude between unit and system specs, so a single
# seconds-per-example threshold flags the wrong things.

require 'json'
require 'net/http'
require 'optparse'
require 'uri'

# Both test-summary scripts write into a single note, each owning one marked
# section and byte-preserving the other. scripts/frontend/post_msw_test_summary.mjs
# implements the same contract; changing these markers means changing both.
COMBINED_MARKER = '<!-- test-result-summary -->'

SECTIONS = {
  'msw' => { label: 'MSW Test Result Summary', job: 'jest-msw-integration' },
  'rspec' => { label: 'RSpec Test Result Summary', job: 'rspec:test-summary' }
}.freeze

def section_open(name)
  "<!-- section:#{name} -->"
end

def section_close(name)
  "<!-- /section:#{name} -->"
end

# Replace one section of an existing combined note, leaving the rest byte-identical.
# Appends the section when its markers are absent (older note, or first writer).
def splice_section(body, name, content)
  open_marker = section_open(name)
  close_marker = section_close(name)
  start_idx = body.index(open_marker)
  close_idx = body.index(close_marker)

  if start_idx.nil? || close_idx.nil? || close_idx < start_idx
    return "#{body.rstrip}\n\n#{open_marker}\n#{content}\n#{close_marker}\n"
  end

  "#{body[0...start_idx]}#{open_marker}\n#{content}\n#{body[close_idx..]}"
end

# Stand-in for the counterpart suite, which has not written its section yet.
def placeholder_section(name, job_present:)
  state = if job_present
            '_Pending -- results appear when the job finishes._'
          else
            '_Did not run for this merge request._'
          end

  "### #{SECTIONS.fetch(name)[:label]}\n\n#{state}"
end

# Build a fresh combined note containing our section and a placeholder for the other.
def build_combined_comment(name, content, counterpart_present:)
  other = (SECTIONS.keys - [name]).first
  bodies = { name => content, other => placeholder_section(other, job_present: counterpart_present) }

  lines = [COMBINED_MARKER, '', '## Test Result Summary', '']
  SECTIONS.each_key do |key|
    lines << section_open(key)
    lines << bodies.fetch(key)
    lines << section_close(key)
    lines << ''
  end

  lines.join("\n")
end

SPEC_FILE_RE = /_spec\.rb$/

# Runtime is wall-clock measured on different runners in different pipelines, so
# a small delta says nothing. System specs are the worst case: browser startup
# and Capybara waits swamp any per-example change. A delta counts as signal only
# once it clears both an absolute floor and a share of the file's own runtime.
NOISE_FLOOR_S = 3
NOISE_FLOOR_RATIO = 0.1

# How far we page through the MR diffs API.
DIFFS_PER_PAGE = 100
MAX_DIFF_PAGES = 5

# Transient GitLab API failures are retried with exponential backoff.
MAX_API_ATTEMPTS = 3
MAX_BACKOFF_S = 60

# ---------------------------------------------------------------------------
# CLI option parsing
# ---------------------------------------------------------------------------
def parse_options(argv = ARGV)
  options = {
    job_name: ENV.fetch('CI_JOB_NAME', ''),
    report_path: '',
    report_glob: '',
    artifact_path: '',
    baseline_path: '',
    knapsack_url: 'https://gitlab-org.gitlab.io/gitlab/knapsack/report-master.json',
    job_url: ENV.fetch('CI_JOB_URL', ''),
    dry_run: false
  }

  OptionParser.new do |opts|
    opts.on('--job-name NAME', 'CI job name (default: $CI_JOB_NAME)') { |v| options[:job_name] = v }
    opts.on('--report-path PATH', 'Path to a single local RSpec JSON report') { |v| options[:report_path] = v }
    opts.on('--report-glob PATTERN', 'Glob matching every RSpec JSON report to aggregate') do |v|
      options[:report_glob] = v
    end
    opts.on('--artifact-path PATH', 'Path within the artifact archive for master baseline lookup') do |v|
      options[:artifact_path] = v
    end
    opts.on('--baseline-path PATH', 'Where to write the compact baseline this job publishes') do |v|
      options[:baseline_path] = v
    end
    opts.on('--knapsack-url URL',
      'URL of the knapsack master report (default: GitLab Pages knapsack report)') do |v|
      options[:knapsack_url] = v
    end
    opts.on('--job-url URL', 'CI job URL (default: $CI_JOB_URL)') { |v| options[:job_url] = v }
    opts.on('--dry-run', 'Print comment to stdout instead of posting it') { options[:dry_run] = true }
  end.parse!(argv)

  options
end

# ---------------------------------------------------------------------------
# Duration formatting helpers
# ---------------------------------------------------------------------------
def format_duration(seconds)
  return '—' if seconds.nil? || seconds < 0

  rounded = seconds.round
  # Whole-suite runtimes reach tens of hours, so minutes alone read poorly.
  return "#{rounded / 3600}h #{rounded % 3600 / 60}m #{rounded % 60}s" if rounded >= 3600

  m = rounded / 60
  s = rounded % 60
  m > 0 ? "#{m}m #{s}s" : "#{s}s"
end

# Whether a runtime delta is too small to distinguish from run-to-run variance.
def within_noise?(delta_runtime_s, master_runtime_s)
  return false if delta_runtime_s.nil?

  threshold = [NOISE_FLOOR_S, (master_runtime_s || 0) * NOISE_FLOOR_RATIO].max
  delta_runtime_s.abs < threshold
end

def format_signed_duration(seconds)
  return '—' if seconds.nil?
  # A sub-second delta rounds to zero, and a signed zero reads as noise.
  return '0s' if seconds.round == 0

  sign = seconds >= 0 ? '+' : '−'
  "#{sign}#{format_duration(seconds.abs)}"
end

# ---------------------------------------------------------------------------
# Report parsing
# ---------------------------------------------------------------------------

# Normalise an RSpec JSON report's file_path to a repo-relative path.
# RSpec records paths like "./spec/models/user_spec.rb"; strip the leading "./".
def normalize_report_path(path)
  return '' if path.nil? || path.empty?

  # Strip leading "./" if present
  path = path.delete_prefix('./')

  # If it's still an absolute path, strip the project root prefix
  if path.start_with?('/')
    root = ENV.fetch('CI_PROJECT_DIR', Dir.pwd)
    root = root.chomp('/')
    path = path.start_with?(root) ? path[root.length..].sub(%r{\A/+}, '') : path
  end

  path
end

# Keep only the first run of each example, tracking ids across reports.
#
# `rspec fail-fast` re-runs every spec file an MR changed and the predictive
# jobs run those files again, so summing both reports doubles the example count
# and runtime of each changed file. Examples without an id are kept, so an
# unexpected report shape under-counts duplicates instead of dropping rows.
#
# @param seen_ids [Set<String>] mutated; share one set across all reports
# @return [Array<Hash>]
def reject_duplicate_examples(examples, seen_ids)
  examples.select { |example| example['id'].nil? || seen_ids.add?(example['id']) }
end

# Build a per-file map of runtime and example count from RSpec JSON examples.
#
# RSpec JSON format (via Support::Formatters::JsonFormatter):
#   { "examples": [ { "id": "...", "description": "...", "status": "...",
#                     "run_time": 1.23, "file_path": "./spec/..." }, ... ] }
#
# @return [Hash<String, Hash>] path => { runtime_s: Float, example_count: Integer }
def per_file_from_examples(examples)
  per_file = {}

  examples.each do |example|
    path = normalize_report_path(example['file_path'] || '')
    next if path.empty?

    per_file[path] ||= { runtime_s: 0.0, example_count: 0 }
    per_file[path][:runtime_s] += example['run_time'] || 0.0
    per_file[path][:example_count] += 1
  end

  per_file
end

# Parse the RSpec JSON report at the given path.
#
# @param seen_ids [Set<String>] example ids already counted by an earlier report
# @return [Hash, nil] parsed stats or nil when the file is missing/unreadable
def parse_report(report_path, seen_ids = Set.new)
  return if report_path.nil? || report_path.empty? || !File.exist?(report_path)

  data = JSON.parse(File.read(report_path))
  examples = reject_duplicate_examples(data['examples'] || [], seen_ids)

  {
    failed: examples.count { |e| e['status'] == 'failed' },
    per_file: per_file_from_examples(examples)
  }
rescue JSON::ParserError, Errno::ENOENT => e
  warn "[RSpec] Could not parse report at #{report_path}: #{e.message}"
  nil
end

# Expand the report glob, dropping retry reports.
#
# A retried job writes rspec/rspec-retry-$CI_JOB_ID.json and then merges it back
# into rspec/rspec-$CI_JOB_ID.json without deleting it, so the retried examples
# are already counted. Globbing both would inflate every flaky job.
#
# @return [Array<String>]
def report_paths(glob)
  Dir.glob(glob).reject { |path| File.basename(path).start_with?('rspec-retry-') }.sort
end

# Aggregate every RSpec JSON report in the pipeline into one stats hash.
#
# The suite is split across hundreds of parallel jobs, each writing its own
# rspec/rspec-$CI_JOB_ID.json. A single job's report describes only its slice,
# so the summary has to sum them -- but a spec file can run in more than one
# job, so the reports are deduplicated by example id before being summed.
#
# @param paths [Array<String>]
# @return [Hash, nil] merged stats, or nil when no report could be read
def parse_reports(paths)
  seen_ids = Set.new
  reports = paths.filter_map { |path| parse_report(path, seen_ids) }
  return if reports.empty?

  per_file = {}

  reports.each do |report|
    report[:per_file].each do |path, file|
      entry = (per_file[path] ||= { runtime_s: 0.0, example_count: 0 })
      entry[:runtime_s] += file[:runtime_s]
      entry[:example_count] += file[:example_count]
    end
  end

  {
    failed: reports.sum { |r| r[:failed] },
    per_file: per_file
  }
end

# Read a compact baseline written by write_baseline back into the per_file shape.
#
# @return [Hash<String, Hash>] path => { runtime_s: Float, example_count: Integer }
def per_file_from_baseline(data)
  (data['per_file'] || {}).transform_values do |entry|
    { runtime_s: entry['runtime_s'].to_f, example_count: entry['example_count'].to_i }
  end
end

# Publish a compact per-file baseline for future runs to compare against.
#
# The RSpec JSON report is named after the job that produced it
# (rspec/rspec-$CI_JOB_ID.json), so its path can never be used to address
# master's copy. This writes the handful of numbers the delta actually needs
# under a stable, job-independent name that the artifacts API can resolve.
def write_baseline(baseline_path, stats)
  return if baseline_path.nil? || baseline_path.empty? || stats.nil?

  per_file = stats[:per_file].transform_values do |f|
    { 'runtime_s' => f[:runtime_s].round(3), 'example_count' => f[:example_count] }
  end

  File.write(baseline_path, JSON.generate({ 'per_file' => per_file }))
  puts "[RSpec] Wrote baseline for #{per_file.size} files to #{baseline_path}."
rescue SystemCallError => e
  warn "[RSpec] Could not write baseline to #{baseline_path}: #{e.message}"
end

def status_emoji(stats)
  return '⚠️' unless stats

  stats[:failed] > 0 ? '❌' : '✅'
end

# ---------------------------------------------------------------------------
# Actionable diff computation
# ---------------------------------------------------------------------------

# Build a single file diff entry comparing current run against master baseline.
#
# @return [Hash] file diff entry
def file_diff_entry(cf, current, master)
  # A file the MR only modified, with no baseline row, has an unknown delta.
  # Diffing it against zero would report examples it already had on master -- or
  # ones the MR deleted -- as newly added.
  no_baseline_row = master.nil? && !cf[:is_new]
  master_runtime_s = master ? master[:runtime_s] : 0.0
  master_examples = master ? master[:example_count] : 0

  # The knapsack baseline carries runtime but no example counts, so a row can
  # know one delta and not the other. Resolving them together would discard the
  # runtime delta that knapsack exists to provide.
  unknown_runtime = no_baseline_row || master_runtime_s.nil?
  unknown_examples = no_baseline_row || master_examples.nil?

  {
    path: cf[:path],
    is_new: cf[:is_new],
    is_deleted: cf[:is_deleted],
    current_runtime_s: current[:runtime_s],
    master_runtime_s: master ? master_runtime_s : nil,
    delta_runtime_s: unknown_runtime ? nil : current[:runtime_s] - master_runtime_s,
    current_examples: current[:example_count],
    master_examples: master ? master_examples : nil,
    delta_examples: unknown_examples ? nil : current[:example_count] - master_examples
  }
end

# Diff each changed spec file that ran in this job against the master baseline
# and reduce it to a single actionable number: seconds per new example.
#
# @param changed_files [Array<Hash>] from fetch_changed_spec_files
# @param report [Hash, nil] from parse_report
# @param baseline [Hash, nil] from fetch_master_baseline
# @return [Hash] { files: Array, added_runtime_s: Float, added_examples: Integer }
def compute_actionable(changed_files:, report:, baseline:)
  report_per_file = report&.dig(:per_file) || {}
  master_per_file = baseline&.dig(:per_file) || {}

  files = []
  added_runtime_s = 0.0
  added_examples = 0
  examples_known = false

  changed_files.each do |cf|
    # Renamed and deleted files exist on master under their old path.
    master = master_per_file[cf[:old_path]]
    current = report_per_file[cf[:path]]

    # A file this MR deletes cannot appear in this pipeline's report, so its
    # master cost is what the MR gives back. Absence alone cannot stand in for
    # zero: a modified file may simply not have run in this pipeline.
    current ||= { runtime_s: 0.0, example_count: 0 } if cf[:is_deleted] && master

    # Only attribute cost to files that actually ran in this job's report.
    next unless current

    entry = file_diff_entry(cf, current, master)
    files << entry

    # An unknown delta cannot be attributed to this MR, so it stays out of the
    # totals -- each one independently, since a row can know only one of them.
    added_runtime_s += entry[:delta_runtime_s] if entry[:delta_runtime_s]

    next unless entry[:delta_examples]

    added_examples += entry[:delta_examples]
    examples_known = true
  end

  {
    files: files,
    added_runtime_s: added_runtime_s,
    added_examples: added_examples,
    examples_known: examples_known
  }
end

# ---------------------------------------------------------------------------
# Comment building
# ---------------------------------------------------------------------------
# -- comment-building helper mirrors MSW script structure
def build_file_row(file)
  tag = if file[:is_new]
          ' (new)'
        elsif file[:is_deleted]
          ' (deleted)'
        else
          ''
        end

  delta_runtime_s = file[:delta_runtime_s]

  master_rt_str = file[:master_runtime_s].nil? ? '—' : format_duration(file[:master_runtime_s])

  runtime_cell = "#{master_rt_str} -> #{format_duration(file[:current_runtime_s])}"
  delta_cell = if delta_runtime_s.nil?
                 '—'
               elsif within_noise?(delta_runtime_s, file[:master_runtime_s])
                 'within noise'
               else
                 format_signed_duration(delta_runtime_s)
               end

  "| `#{file[:path]}`#{tag} | #{runtime_cell} | #{delta_cell} |"
end

# Append the actionable headline to lines based on baseline availability.
# -- mirrors MSW script structure
def append_headline(lines, actionable, has_baseline)
  unless has_baseline
    lines << '> No master baseline available yet -- runtime delta omitted.'
    return
  end

  added = actionable[:added_examples]
  file_count = actionable[:files].length
  file_word = file_count == 1 ? 'file' : 'files'
  delta = format_signed_duration(actionable[:added_runtime_s])

  if added > 0
    example_word = added == 1 ? 'example' : 'examples'
    lines << "**+#{added} new #{example_word}** across #{file_count} #{file_word} | **#{delta} vs master**"
  elsif added < 0
    example_word = added == -1 ? 'example' : 'examples'
    lines << "**#{added.abs} #{example_word} removed** across #{file_count} #{file_word} | **#{delta} vs master**"
  elsif !actionable[:files].empty?
    # A baseline without example counts (knapsack) makes zero mean "unknown",
    # not "unchanged", so only the runtime delta can be claimed.
    lines << if actionable.fetch(:examples_known, true)
               "Changed #{file_count} spec #{file_word} with no change in example count | **#{delta} vs master**"
             else
               "Changed #{file_count} spec #{file_word} | **#{delta} vs master**"
             end
  else
    lines << 'No changed RSpec spec files detected in this MR.'
  end
end

# Build the full MR comment body.
#
# @param job_name [String]
# @param job_url [String]
# @param stats [Hash, nil] from parse_report
# @param baseline [Hash, nil] from fetch_master_baseline
# @param actionable [Hash] from compute_actionable
# @param truncated [Boolean]
# @return [String]
def build_comment(job_name:, job_url:, stats:, baseline:, actionable:, truncated: false)
  emoji = status_emoji(stats)
  lines = ["### #{SECTIONS.fetch('rspec')[:label]}", '']

  unless stats
    lines << "**#{job_name}**: #{emoji} [job log](#{job_url}) -- no JSON report found"
    lines << ''
    return lines.join("\n")
  end

  has_baseline = baseline && !baseline.fetch(:per_file, {}).empty?

  lines << "**#{job_name}**: #{emoji} [job log](#{job_url})"
  lines << ''

  if truncated
    cap = DIFFS_PER_PAGE * MAX_DIFF_PAGES
    lines << "> ⚠️ **Warning**: This MR changes #{cap}+ files, so the per-file breakdown is truncated."
    lines << ''
  end

  append_headline(lines, actionable, has_baseline)
  lines << ''

  if actionable[:files].any?
    lines << '<details><summary>Per-file breakdown</summary>'
    lines << ''
    # No example column: the knapsack baseline carries runtime only, so a master
    # example count is never available for a file that already existed.
    lines << '| File | Runtime (master -> now) | Delta Runtime |'
    lines << '| --- | --- | --- |'
    actionable[:files].each { |f| lines << build_file_row(f) }
    lines << ''
    lines << '</details>'
    lines << ''
  end

  lines.join("\n")
end

# ---------------------------------------------------------------------------
# HTTP / GitLab API helpers
# ---------------------------------------------------------------------------
def sleep_seconds(seconds)
  sleep(seconds)
end

def retryable_status?(status)
  status == 429 || status >= 500
end

# Perform a GitLab API request, retrying transient failures with exponential
# backoff (2**attempt seconds, capped at MAX_BACKOFF_S).
#
# @param method [String] HTTP method ('GET', 'POST', 'PUT')
# @param path [String] API path (e.g. '/projects/123/merge_requests/1/notes')
# @param body [Hash, nil] request body (JSON-encoded)
# @return [Hash, Array] parsed JSON response
def api_request(method, path, body = nil)
  token = ENV.fetch('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', '')
  base = ENV.fetch('CI_API_V4_URL', 'https://gitlab.com/api/v4')
  uri = URI("#{base}#{path}")

  attempt = 1

  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = case method
              when 'GET'  then Net::HTTP::Get.new(uri)
              when 'POST' then Net::HTTP::Post.new(uri)
              when 'PUT'  then Net::HTTP::Put.new(uri)
              else raise ArgumentError, "Unsupported HTTP method: #{method}"
              end

    request['PRIVATE-TOKEN'] = token
    request['Content-Type'] = 'application/json'
    request.body = body.to_json if body

    response = http.request(request)
    status = response.code.to_i

    raise "GitLab API #{status} on #{method} #{path}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue RuntimeError => e
    # Re-raise non-retryable errors (4xx that are not 429) immediately.
    status_match = e.message.match(/GitLab API (\d+)/)
    if status_match
      status = status_match[1].to_i
      if retryable_status?(status) && attempt < MAX_API_ATTEMPTS
        backoff = [2**attempt, MAX_BACKOFF_S].min
        warn "[RSpec] GitLab API #{status} on #{method} #{path} -- retrying in #{backoff}s " \
          "(attempt #{attempt}/#{MAX_API_ATTEMPTS})."
        sleep_seconds(backoff)
        attempt += 1
        retry
      end
    end

    raise
  rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    if attempt < MAX_API_ATTEMPTS
      backoff = [2**attempt, MAX_BACKOFF_S].min
      warn "[RSpec] Network error on #{method} #{path} (#{e.message}) -- retrying in #{backoff}s " \
        "(attempt #{attempt}/#{MAX_API_ATTEMPTS})."
      sleep_seconds(backoff)
      attempt += 1
      retry
    end

    raise
  end
end

# Fetch the list of added/modified/deleted spec files in this MR from the diffs
# API. Renamed and deleted files keep their old path for baseline lookup.
#
# @return [Hash] { files: Array<Hash>, truncated: Boolean }
def fetch_changed_spec_files(project_id, mr_iid)
  files = []
  truncated = false

  (1..MAX_DIFF_PAGES).each do |page|
    diffs = api_request(
      'GET',
      "/projects/#{project_id}/merge_requests/#{mr_iid}/diffs?per_page=#{DIFFS_PER_PAGE}&page=#{page}"
    )
    break unless diffs.is_a?(Array) && !diffs.empty?

    diffs.each do |diff|
      new_path = diff['new_path']
      old_path = diff['old_path'] || new_path
      deleted = diff['deleted_file'] == true
      # A deleted file has no content on this branch, so only its old path names it.
      path = deleted ? old_path : new_path
      next unless path && SPEC_FILE_RE.match?(path)

      files << {
        path: path,
        is_new: diff['new_file'] == true,
        is_deleted: deleted,
        old_path: old_path
      }
    end

    if diffs.length < DIFFS_PER_PAGE
      break
    elsif page == MAX_DIFF_PAGES
      truncated = true
    end
  end

  { files: files, truncated: truncated }
rescue StandardError => e
  warn "[RSpec] Could not fetch MR changed files: #{e.message}"
  { files: [], truncated: false }
end

# Fetch the knapsack master report from the GitLab Pages URL.
#
# The knapsack report format is a flat JSON object:
#   { "spec/path/file_spec.rb": <average_duration_float>, ... }
#
# We convert it into the same per_file shape the rest of the script uses,
# with example_count set to nil (knapsack does not track example counts).
#
# @param url [String] URL of the knapsack report JSON
# @return [Hash, nil] { per_file: Hash } or nil when unavailable
def fetch_knapsack_baseline(url)
  return if url.nil? || url.empty?

  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  data = JSON.parse(response.body)
  per_file = data.transform_values do |duration|
    { runtime_s: duration.to_f, example_count: nil }
  end

  puts "[RSpec] Knapsack baseline loaded: #{per_file.size} files from #{url}."
  { per_file: per_file }
rescue StandardError => e
  puts "[RSpec] Could not fetch knapsack baseline (#{e.message}) -- skipping delta."
  nil
end

# Fetch the master baseline for the given job name.
#
# Uses the "download a single artifact file by reference name" API, which
# resolves to the artifact from the latest successful pipeline on `master`
# for the given job.
#
# @return [Hash, nil] { per_file: Hash } or nil when unavailable
def fetch_master_baseline(project_id, job_name, report_artifact_path)
  return if report_artifact_path.nil? || report_artifact_path.empty?

  encoded_job = URI.encode_www_form_component(job_name)
  artifact_url = "/projects/#{project_id}/jobs/artifacts/master/raw/#{report_artifact_path}?job=#{encoded_job}"
  data = api_request('GET', artifact_url)
  puts "[RSpec] Master baseline: latest successful '#{job_name}' on master."
  { per_file: per_file_from_baseline(data) }
rescue StandardError => e
  puts "[RSpec] No master baseline available (#{e.message}) -- skipping delta."
  nil
end

# Find an existing summary note on the MR (matched by marker + author).
#
# @return [Hash, nil] the note object or nil
def find_existing_note(project_id, mr_iid)
  author_username = nil

  begin
    me = api_request('GET', '/user')
    author_username = me['username']
  rescue StandardError => e
    warn "[RSpec] Could not resolve current user (#{e.message}) -- matching on marker only."
  end

  (1..3).each do |page|
    notes = api_request(
      'GET',
      "/projects/#{project_id}/merge_requests/#{mr_iid}/notes" \
        "?per_page=100&page=#{page}&order_by=created_at&sort=desc"
    )
    hit = notes.find do |note|
      note['body']&.include?(COMBINED_MARKER) &&
        (author_username.nil? || note.dig('author', 'username') == author_username)
    end
    return hit if hit
    break if notes.length < 100
  end

  nil
rescue StandardError => e
  warn "[RSpec] Could not search for existing note: #{e.message}"
  nil
end

# Whether the counterpart suite's job exists in this pipeline. Distinguishes
# "has not written its section yet" from "does not run for this MR".
def counterpart_job_present?(project_id, job_name)
  pipeline_id = ENV['CI_PIPELINE_ID']
  return false if pipeline_id.nil? || pipeline_id.empty?

  (1..5).each do |page|
    jobs = api_request(
      'GET',
      "/projects/#{project_id}/pipelines/#{pipeline_id}/jobs?per_page=100&page=#{page}&include_retried=false"
    )
    return true if jobs.any? { |job| job['name'] == job_name }
    break if jobs.length < 100
  end

  false
rescue StandardError => e
  warn "[RSpec] Could not look up #{job_name} in the pipeline: #{e.message}"
  false
end

# Write this script's section into the shared summary note, creating it if absent.
def post_or_update_comment(project_id, mr_iid, section_content)
  existing = find_existing_note(project_id, mr_iid)

  unless existing
    counterpart = SECTIONS.fetch('msw')
    comment = build_combined_comment(
      'rspec', section_content,
      counterpart_present: counterpart_job_present?(project_id, counterpart[:job])
    )
    api_request('POST', "/projects/#{project_id}/merge_requests/#{mr_iid}/notes", { body: comment })
    puts 'Posted new test summary comment.'
    return
  end

  comment = splice_section(existing['body'].to_s, 'rspec', section_content)

  begin
    note_url = "/projects/#{project_id}/merge_requests/#{mr_iid}/notes/#{existing['id']}"
    api_request('PUT', note_url, { body: comment })
    puts "Updated the RSpec section of the test summary comment (note #{existing['id']})."
  rescue StandardError => e
    warn "Could not update note #{existing['id']} (#{e.message}) -- posting a new comment instead."
    api_request('POST', "/projects/#{project_id}/merge_requests/#{mr_iid}/notes", { body: comment })
    puts 'Posted new test summary comment.'
  end
end

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------
def load_stats(opts)
  return parse_report(opts[:report_path]) if opts[:report_glob].empty?

  paths = report_paths(opts[:report_glob])
  puts "[RSpec] Aggregating #{paths.size} report(s) matching #{opts[:report_glob]}."
  parse_reports(paths)
end

def run(argv = ARGV)
  opts = parse_options(argv)

  stats = load_stats(opts)

  # Master pipelines publish the baseline but have no MR to comment on, so this
  # has to happen before the merge-request check below.
  write_baseline(opts[:baseline_path], stats)

  mr_iid = ENV.fetch('CI_MERGE_REQUEST_IID', '')
  if mr_iid.empty?
    puts 'Not a merge-request pipeline -- skipping RSpec summary comment.'
    return
  end

  token = ENV.fetch('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', '')
  if token.empty?
    warn 'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE not set -- cannot post comment.'
    return
  end

  project_id = URI.encode_www_form_component(ENV.fetch('CI_PROJECT_ID', ''))

  # Fetch the baseline: prefer the knapsack Pages report (always up-to-date,
  # no auth required) and fall back to the artifact-based master baseline.
  baseline = fetch_knapsack_baseline(opts[:knapsack_url])
  baseline ||= fetch_master_baseline(project_id, opts[:job_name], opts[:artifact_path])
  changed_result = fetch_changed_spec_files(project_id, mr_iid)
  changed_files = changed_result[:files]
  truncated = changed_result[:truncated]

  actionable = compute_actionable(changed_files: changed_files, report: stats, baseline: baseline)

  comment = build_comment(
    job_name: opts[:job_name],
    job_url: opts[:job_url],
    stats: stats,
    baseline: baseline,
    actionable: actionable,
    truncated: truncated
  )

  added_rt = format_signed_duration(actionable[:added_runtime_s].round)
  puts "[RSpec] New examples: +#{actionable[:added_examples]} | Added runtime: #{added_rt}"

  if opts[:dry_run]
    puts "\n[RSpec] --dry-run: comment NOT posted. Rendered comment below:\n"
    puts comment
    return
  end

  post_or_update_comment(project_id, mr_iid, comment)
end

# The job has no allow_failure, so a GitLab API error (a 403 on the token, a 500
# on the notes endpoint) would block the merge over a report nobody reads as a
# gate. Reporting must never fail the pipeline.
def run_safely(argv = ARGV)
  run(argv)
rescue StandardError => e
  warn "[RSpec] Test summary skipped: #{e.class}: #{e.message}"
end

# Only run when invoked directly, so the spec can require this file and call the
# methods it wants.
run_safely if $PROGRAM_NAME == __FILE__
