# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

# rubocop:disable Layout/LineLength -- we need to construct the URLs

class SemgrepResultProcessor
  ALLOWED_PROJECT_DIRS = %w[/builds/gitlab-org/gitlab].freeze
  ALLOWED_API_URLS = %w[https://gitlab.com/api/v4].freeze

  UNIQUE_COMMENT_RULES_IDS = %w[builds.sast-custom-rules.appsec-pings.glappsec_ci-job-token builds.sast-custom-rules.secure-coding-guidelines.ruby.glappsec_insecure-regex].freeze
  # Remove this when the feature is fully working
  MESSAGE_FOOTER = <<~FOOTER


    <small>
    This AppSec automation is currently under testing.
    Use ~"appsec-sast::helpful" or ~"appsec-sast::unhelpful" for quick feedback.
    To stop the bot from further commenting, you can use the ~"appsec-sast::stop" label.
    For any detailed feedback, [add a comment here](https://gitlab.com/gitlab-com/gl-security/product-security/appsec/sast-custom-rules/-/issues/38).
    </small>

  FOOTER

  def initialize(report_path = "#{ENV['CI_PROJECT_DIR']}/gl-sast-report.json")
    @artifact_relative_path = report_path
  end

  def execute
    perform_allowlist_check
    semgrep_results = get_sast_results
    unique_results = filter_duplicate_findings(semgrep_results)
    if sast_stop_label_present?
      puts "Not adding comments for this MR as it has the appsec-sast::stop label. Here are the new unique findings that would have otherwise been posted: #{unique_results}"
      return
    end

    puts "Found the following unique results: #{unique_results}"
    create_inline_comments(unique_results)

  rescue StandardError => e
    puts "An error occurred: #{e.message}"

    exit 0
  end

  def perform_allowlist_check
    # Validate CI_PROJECT_DIR and CI_API_V4_URL against the
    # allowlist to protect against pipeline attacks

    unless ALLOWED_PROJECT_DIRS.include?(ENV['CI_PROJECT_DIR'])
      puts "Error: CI_PROJECT_DIR '#{ENV['CI_PROJECT_DIR']}' is not allowed."
      exit 1
    end

    return if ALLOWED_API_URLS.include?(ENV['CI_API_V4_URL'])

    puts "Error: CI_API_V4_URL '#{ENV['CI_API_V4_URL']}' is not allowed."
    exit 1
  end

  def get_sast_results
    # Load SAST report
    raw_data = File.read(@artifact_relative_path)
    data = JSON.parse(raw_data)

    fingerprint_message_dict = {}

    if data["results"].empty?
      puts "No findings."
      exit 0
    end

    results = data["results"]

    results.each do |result|
      # Remove version suffix from fingerprint
      fingerprint = result["extra"]["fingerprint"].sub(/_\d+$/, '')
      path = result["path"]
      check_id = result["check_id"]
      line = result["start"]["line"]
      message = result["extra"]["message"].tr('"\'', '')

      fingerprint_message_dict[fingerprint] = { path: path, line: line, message: message, check_id: check_id }
    end

    # Print the results to console
    fingerprint_message_dict.each do |fingerprint, info|
      path = info[:path]
      line = info[:line]
      message = info[:message]

      puts "Finding (Fingerprint: #{fingerprint}) in #{path} at line #{line}: #{message}"
    end

    fingerprint_message_dict
  end

  def filter_duplicate_findings(fingerprint_messages)
    existing_comments = get_existing_comments || []

    existing_headers = existing_comments.filter_map do |comment|
      comment["body"].match(/<!-- (.*?) -->/)&.captures&.first
    end
    existing_fingerprints = existing_headers.map do |message|
      JSON.parse(message)["fingerprint"]
    end
    unique_rule_findings = {}
    fingerprint_messages.each do |fingerprint, finding|
      next unless UNIQUE_COMMENT_RULES_IDS.include?(finding[:check_id])

      fingerprint_messages.delete(fingerprint) if unique_rule_findings[finding[:check_id]]

      unique_rule_findings[finding[:check_id]] = true
    end
    fingerprint_messages.reject do |fingerprint, _|
      existing_fingerprints.include?(fingerprint)
    end
  end

  def create_inline_comments(path_line_message_dict)
    base_sha, head_sha, start_sha = populate_commits_from_versions

    # Create new comments for remaining findings
    path_line_message_dict.each do |fingerprint, finding|
      header_information = JSON.dump({ 'fingerprint' => fingerprint, 'check_id' => finding[:check_id] })
      message_header = "<!-- #{header_information} -->"
      new_line = finding[:line]
      message = finding[:message]
      uri = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}/discussions")
      message_from_bot = "#{message_header}\n#{message}\n#{MESSAGE_FOOTER}"
      request = Net::HTTP::Post.new(uri)
      request["PRIVATE-TOKEN"] = ENV['CUSTOM_SAST_RULES_BOT_PAT']
      request.set_form_data(
        "position[position_type]" => "text",
        "position[base_sha]" => base_sha,
        "position[head_sha]" => head_sha,
        "position[start_sha]" => start_sha,
        "position[new_path]" => finding[:path],
        "position[old_path]" => finding[:path],
        "position[new_line]" => new_line,
        "body" => message_from_bot
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      # if response is not 201, exit with error
      next if response.instance_of?(Net::HTTPCreated)

      puts "Failed to post inline comment with status code #{response.code}: #{response.body}. Posting normal comment instead."
      post_comment message_from_bot
    end
  end

  def sast_stop_label_present?
    labels = ENV['CI_MERGE_REQUEST_LABELS'] || ""
    labels.split(',').map(&:strip).include?('appsec-sast::stop')
  end

  private

  def get_existing_comments
    # Retrieve existing comments on the merge request
    notes_url = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}/notes")
    request = Net::HTTP::Get.new(notes_url)
    request["PRIVATE-TOKEN"] = ENV['CUSTOM_SAST_RULES_BOT_PAT']

    response = Net::HTTP.start(notes_url.hostname, notes_url.port, use_ssl: notes_url.scheme == 'https') do |http|
      http.request(request)
    end

    # if response is not 200, exit with error
    return JSON.parse(response.body) if response.instance_of?(Net::HTTPOK)

    puts "Failed to fetch comments with status code #{response.code}: #{response.body}"
    post_comment "Failed to fetch comments: #{response.body}. /cc @gitlab-com/gl-security/product-security/appsec for visibility."

    exit 0
  end

  def populate_commits_from_versions
    # Fetch base_commit_sha, head_commit_sha and
    # start_commit_sha required for creating inline comment
    versions_url = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}/versions")

    request = Net::HTTP::Get.new(versions_url)
    request["PRIVATE-TOKEN"] = ENV['CUSTOM_SAST_RULES_BOT_PAT']

    response = Net::HTTP.start(versions_url.hostname, versions_url.port, use_ssl: versions_url.scheme == 'https') do |http|
      http.request(request)
    end

    if response.instance_of?(Net::HTTPOK)
      commits = JSON.parse(response.body)[0]
    else
      puts "Failed to fetch versions with status code #{response.code}: #{response.body}"
      post_comment "Failed to fetch versions: #{response.body}. /cc @gitlab-com/gl-security/product-security/appsec for visibility."

      exit 0
    end

    base_sha = commits['base_commit_sha']
    head_sha = commits['head_commit_sha']
    start_sha = commits['start_commit_sha']

    [base_sha, head_sha, start_sha]
  end

  def post_comment(message)
    uri = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}/discussions?body=#{message}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.request_uri)
    request['PRIVATE-TOKEN'] = ENV['CUSTOM_SAST_RULES_BOT_PAT']

    response = http.request(request)

    return if response.instance_of?(Net::HTTPCreated)

    puts "Failed to post comment #{response.code}: #{response.body}"
    # if we cannot even post a comment, fail the pipeline
    # change this to `exit 1` when specs are ready
    exit 0
  end
end

SemgrepResultProcessor.new.execute if $PROGRAM_NAME == __FILE__

# rubocop:enable Layout/LineLength
