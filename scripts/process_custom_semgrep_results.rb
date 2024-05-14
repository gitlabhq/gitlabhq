# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

# rubocop:disable Layout/LineLength -- we need to construct the URLs

ALLOWED_PROJECT_DIRS = %w[/builds/gitlab-org/gitlab].freeze
ALLOWED_API_URLS = %w[https://gitlab.com/api/v4].freeze

# Remove this when the feature is fully working
MESSAGE_FOOTER = "\n\nThis AppSec automation is currently under testing. " \
                 "Please leave any feedback [here](https://gitlab.com/gitlab-com/gl-security/product-security/appsec/sast-custom-rules/-/issues/38)."

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

def get_sast_results
  # Load SAST report
  artifact_relative_path = "#{ENV['CI_PROJECT_DIR']}/gl-sast-report.json"
  raw_data = File.read(artifact_relative_path)
  data = JSON.parse(raw_data)

  path_line_message_dict = {}

  if data["results"].empty?
    puts "No findings."
    exit 0
  end

  # Extract findings from SAST report
  results = data["results"]

  # Initialize path_line_message_dict hash {path: [line_x: message_x, line_y: message:y]}
  results.each do |result|
    path = result["path"]
    line = result["start"]["line"]
    message = result["extra"]["message"]

    # If the path doesn't exist in the dictionary, initialize it with an empty array
    path_line_message_dict[path] ||= []

    # Append finding (line and message) to the array associated with the path
    path_line_message_dict[path].push({ line: line, message: message })
  end

  # Print the results to console
  path_line_message_dict.each do |path, info|
    info.each do |finding|
      line = finding[:line]
      message = finding[:message]

      puts "Finding in #{path} at line #{line}: #{message}"
    end
  end

  path_line_message_dict
end

def remove_duplicate_findings(path_line_message_dict)
  # Retrieve existing comments on the merge request
  notes_url = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}/notes")
  request = Net::HTTP::Get.new(notes_url)
  request["PRIVATE-TOKEN"] = ENV['CUSTOM_SAST_RULES_BOT_PAT']

  response = Net::HTTP.start(notes_url.hostname, notes_url.port, use_ssl: notes_url.scheme == 'https') do |http|
    http.request(request)
  end

  # if response is not 200, exit with error
  if response.instance_of?(Net::HTTPOK)
    existing_comments = JSON.parse(response.body)
  else
    puts "Failed to fetch comments with status code #{response.code}: #{response.body}"
    post_comment "Failed to fetch comments: #{response.body}. /cc @gitlab-com/gl-security/product-security/appsec for visibility."

    exit 0
  end

  # Identify and remove duplicate findings
  existing_comments.each do |comment|
    next unless comment['author']['id'].to_s == ENV['BOT_USER_ID'].to_s
    next unless comment['type'] == 'DiffNote'

    puts "existing comment from BOT: #{comment}"
    existing_path = comment['position']['new_path']
    existing_line = comment['position']['new_line']
    existing_message = comment['body']

    puts "Found existing comment in file #{existing_path} for line #{existing_line}" if path_line_message_dict[existing_path].include?({ line: existing_line,
                                                                                                                                         message: existing_message })

    path_line_message_dict[existing_path].delete({ line: existing_line, message: existing_message }) if path_line_message_dict[existing_path].include?({ line: existing_line,
                                                                                                                                                         message: existing_message })
  end
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

def create_inline_comments(path_line_message_dict)
  base_sha, head_sha, start_sha = populate_commits_from_versions

  # Create new comments for remaining findings
  path_line_message_dict.each do |path, info|
    new_path = old_path = path

    info.each do |finding|
      new_line = finding[:line]
      message = finding[:message]
      uri = URI.parse("#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_MERGE_REQUEST_PROJECT_ID']}/merge_requests/#{ENV['CI_MERGE_REQUEST_IID']}/discussions")

      request = Net::HTTP::Post.new(uri)
      request["PRIVATE-TOKEN"] = ENV['CUSTOM_SAST_RULES_BOT_PAT']
      request.set_form_data(
        "position[position_type]" => "text",
        "position[base_sha]" => base_sha,
        "position[head_sha]" => head_sha,
        "position[start_sha]" => start_sha,
        "position[new_path]" => new_path,
        "position[old_path]" => old_path,
        "position[new_line]" => new_line,
        "body" => message + MESSAGE_FOOTER
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      # if response is not 201, exit with error
      next if response.instance_of?(Net::HTTPCreated)

      puts "Failed to post inline comment with status code #{response.code}: #{response.body}"
      post_comment "SAST finding at line #{info[:line]} in file #{path}: #{info[:message]}. " \
                   "\n\n Ping `@gitlab-com/gl-security/product-security/appsec` if you need assistance regarding this finding." + MESSAGE_FOOTER

      exit 0
    end
  end
end

perform_allowlist_check
path_line_message_dict = get_sast_results
remove_duplicate_findings(path_line_message_dict)
create_inline_comments(path_line_message_dict)

# rubocop:enable Layout/LineLength
