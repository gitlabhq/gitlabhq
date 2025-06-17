# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative '../gems/gitlab-utils/lib/gitlab/utils/strong_memoize'

# rubocop:disable Layout/LineLength -- we need to construct the URLs

class SemgrepResultProcessor
  include Gitlab::Utils::StrongMemoize

  ALLOWED_PROJECT_DIRS = %w[/builds/gitlab-org/gitlab].freeze
  ALLOWED_API_URLS = %w[https://gitlab.com/api/v4].freeze
  UNIQUE_COMMENT_RULES_IDS = %w[builds.sast-custom-rules.appsec-pings.glappsec_ci-job-token builds.sast-custom-rules.secure-coding-guidelines.ruby.glappsec_insecure-regex].freeze
  APPSEC_HANDLE = "@gitlab-com/gl-security/appsec"

  LABEL_INSTRUCTION = 'Apply the ~"appsec-sast-ping::resolved" label after reviewing.'

  MESSAGE_SCG_PING_APPSEC =
    "#{APPSEC_HANDLE} please review this finding, which is a potential " \
      'violation of [GitLab\'s secure coding guidelines]' \
      '(https://docs.gitlab.com/development/secure_coding_guidelines/). ' \
      "#{LABEL_INSTRUCTION}".freeze

  MESSAGE_S1_PING_APPSEC =
    "#{APPSEC_HANDLE} please review this finding. This MR potentially " \
      'reintroduces code from a past S1 issue. ' \
      "#{LABEL_INSTRUCTION}".freeze

  MESSAGE_PING_APPSEC =
    "#{APPSEC_HANDLE} please review this finding. " \
      "#{LABEL_INSTRUCTION}".freeze

  MESSAGE_FOOTER = <<~FOOTER


    <small>
    This automation belongs to AppSec.
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
    if sast_stop_label_present? || pipeline_tier_three_label_present?
      puts "Not adding comments for this MR as it has the appsec-sast::stop / pipeline::tier-3 label. Here are the new unique findings that would have otherwise been posted: #{unique_results}"
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
      check_id = finding[:check_id]
      uri = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}/discussions")
      suffix = if check_id&.start_with?("builds.sast-custom-rules.secure-coding-guidelines")
                 "\n#{MESSAGE_SCG_PING_APPSEC}"
               elsif check_id&.start_with?("builds.sast-custom-rules.s1")
                 "\n#{MESSAGE_S1_PING_APPSEC}"
               else
                 "\n#{MESSAGE_PING_APPSEC}"
               end

      message_from_bot = "#{message_header}\n#{message}#{suffix}\n#{MESSAGE_FOOTER}"

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

      if response.instance_of?(Net::HTTPCreated)
        apply_label
        next
      end

      puts "Failed to post inline comment with status code #{response.code}: #{response.body}. Posting normal comment instead."
      post_comment message_from_bot
    end
  end

  private

  def sast_stop_label_present?
    stripped_labels.include?('appsec-sast::stop')
  end

  def pipeline_tier_three_label_present?
    stripped_labels.include?('pipeline::tier-3')
  end

  def stripped_labels
    labels = ENV['CI_MERGE_REQUEST_LABELS'] || ""
    labels.split(',').map(&:strip)
  end
  strong_memoize_attr :stripped_labels

  def apply_label
    uri = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}")
    request = Net::HTTP::Put.new(uri)
    request["PRIVATE-TOKEN"] = ENV['CUSTOM_SAST_RULES_BOT_PAT']
    request.set_form_data(
      "add_labels" => "appsec-sast-ping::unresolved"
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    return if response.instance_of?(Net::HTTPOK)

    puts "Failed to apply labels with status code #{response.code}: #{response.body}"
  end

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
