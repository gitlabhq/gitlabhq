#!/usr/bin/env ruby
# frozen_string_literal: true

# Creates a "DAP foundational flow major updates" issue for each DAP release.
#
# For each release, this script:
# 1. Derives the AI Gateway self-hosted tag range for the current GitLab release
# 2. Compares commits in AI Gateway between those tags
# 3. Filters for likely foundational flow changes using pattern matching
# 4. Creates a pre-populated GitLab issue for human review/curation
#
# Required env vars:
#   CI_COMMIT_TAG               - GitLab release tag, e.g. v18.10.0-ee
#   AIGW_TAGGING_ACCESS_TOKEN   - Token with read access to AI Gateway project
#   DAP_PROJECT_ID              - GitLab project ID where the issue will be created
#   DAP_RELEASE_NOTES_TOKEN     - Token with create-issue access to DAP_PROJECT_ID
#
# Flags:
#   --dry-run   Print the issue title/body instead of creating it

require 'net/http'
require 'uri'
require 'json'

class DapFoundationalFlowsReleaseNotes
  AIGW_PROJECT_ID = "39903947"
  AIGW_PROJECT_URL = "https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist"
  GITLAB_API = "https://gitlab.com/api/v4"

  def initialize
    @dry_run = ARGV.include?('--dry-run')
    @aigw_token = require_env('AIGW_TAGGING_ACCESS_TOKEN')

    @dap_token = @dry_run ? nil : require_env('DAP_RELEASE_NOTES_TOKEN')
    @dap_project_id = @dry_run ? nil : require_env('DAP_PROJECT_ID')
    @commit_tag = require_env('CI_COMMIT_TAG')

    unless @commit_tag =~ /^v(\d+)\.(\d+)\.0-ee$/
      puts "Skipping: #{@commit_tag} is not a minor release tag (vX.Y.0-ee)"
      exit 0
    end

    @major = Regexp.last_match(1).to_i
    @minor = Regexp.last_match(2).to_i
  end

  def execute
    to_tag = "self-hosted-v#{@major}.#{@minor}.0-ee"
    from_tag = previous_self_hosted_tag

    if from_tag.nil?
      puts "Could not find previous self-hosted tag before #{to_tag}, skipping"
      exit 0
    end

    puts "Comparing AI Gateway #{from_tag}...#{to_tag}"

    commits = fetch_commits_between(from_tag, to_tag)
    puts "Total commits: #{commits.length}"

    candidate_commits, other_commits = commits.partition { |c| flow_related?(c) }
    puts "Candidate foundational flow changes: #{candidate_commits.length}"

    title = "DAP foundational flow major updates – v#{@major}.#{@minor}"
    body = build_issue_body(from_tag, to_tag, candidate_commits, other_commits.length)

    if @dry_run
      puts "=== DRY RUN ==="
      puts "Title: #{title}"
      puts ""
      puts body
    else
      issue = create_issue(title, body)
      puts "Issue created: #{issue['web_url']}"
    end
  end

  private

  def previous_self_hosted_tag
    if @minor > 0
      "self-hosted-v#{@major}.#{@minor - 1}.0-ee"
    else
      fetch_latest_self_hosted_tag_for_major(@major - 1)
    end
  end

  def fetch_latest_self_hosted_tag_for_major(major)
    uri = URI("#{GITLAB_API}/projects/#{AIGW_PROJECT_ID}/repository/tags")
    uri.query = URI.encode_www_form(
      search: "self-hosted-v#{major}.",
      order_by: 'version',
      sort: 'desc',
      per_page: 1
    )

    response = api_get(uri, token: @aigw_token)
    tags = JSON.parse(response.body)
    tags.first&.dig('name')
  end

  def fetch_commits_between(from_tag, to_tag)
    from_sha = resolve_tag_sha(from_tag)
    raise "Could not resolve commit SHA for tag #{from_tag}" unless from_sha

    all_commits = []
    page = 1

    loop do
      uri = URI("#{GITLAB_API}/projects/#{AIGW_PROJECT_ID}/repository/commits")
      uri.query = URI.encode_www_form(ref_name: to_tag, per_page: 100, page: page)

      response = api_get(uri, token: @aigw_token)
      commits = JSON.parse(response.body)
      break if commits.empty?

      stop_idx = commits.index { |c| c['id'] == from_sha }
      if stop_idx
        all_commits.concat(commits[0...stop_idx])
        break
      end

      all_commits.concat(commits)
      break if commits.length < 100

      page += 1
    end

    all_commits
  end

  def resolve_tag_sha(tag_name)
    uri = URI("#{GITLAB_API}/projects/#{AIGW_PROJECT_ID}/repository/tags/#{tag_name}")
    response = api_get(uri, token: @aigw_token)
    JSON.parse(response.body).dig('commit', 'id')
  end

  def flow_related?(commit)
    return false if commit['title'].start_with?('Merge branch ', 'Merge remote-tracking branch ')

    message = [commit['title'], commit['message']].compact.join(' ')
    flow_patterns.any? { |pattern| message.match?(pattern) } || flow_files_changed?(commit['id'])
  end

  # Returns true if the commit touched any file whose path contains a flow reference
  # as a directory or file name component (e.g. ai_gateway/workflows/code_review/agent.py).
  def flow_files_changed?(sha)
    uri = URI("#{GITLAB_API}/projects/#{AIGW_PROJECT_ID}/repository/commits/#{sha}/diff")
    uri.query = URI.encode_www_form(per_page: 100)
    response = api_get(uri, token: @aigw_token)
    diffs = JSON.parse(response.body)

    diffs.any? do |diff|
      path = diff['new_path'] || diff['old_path'] || ''
      # Strip extensions so both directory names (fix_pipeline/) and file names
      # (code_review.py) are matched against flow references.
      parts = path.split('/').map { |segment| segment.sub(/\.[^.]+\z/, '') }
      flow_references.any? { |ref| parts.include?(ref) }
    end
  end

  # Reads foundational flow base names from the canonical source in this repo.
  # Parses foundational_flow_reference values (e.g. "code_review/v1" -> "code_review").
  def flow_references
    @flow_references ||= foundational_flow_content
      .to_s
      .scan(/foundational_flow_reference:\s*["'](\w+)/)
      .flatten
      .uniq
  end

  def foundational_flow_content
    File.read(File.expand_path('../ee/app/models/ai/catalog/foundational_flow.rb', __dir__))
  rescue Errno::ENOENT
    nil
  end

  # Patterns to detect foundational flow changes in conventional commit messages.
  # Matches scope prefixes like feat(code_review): or fix(developer/v1): as well as
  # free-text references to flow names.
  #
  # `developer` is intentionally more specific to avoid matching generic uses of the word -
  # requires "duo developer", a conventional commit scope, or "developer flow/path".
  def flow_patterns
    @flow_patterns ||= [
      /foundational.?flow/i,
      %r{\bduo\s+developer\b|\(developer[/)]|\bdeveloper[/\s](?:flow|next|v\d)}i,
      *flow_references.reject { |r| r == 'developer' }
                      .map { |ref| Regexp.new("\\b#{Regexp.escape(ref)}\\b", Regexp::IGNORECASE) }
    ]
  end

  def build_issue_body(from_tag, to_tag, candidate_commits, other_count)
    diff_url = "#{AIGW_PROJECT_URL}/-/compare/#{from_tag}...#{to_tag}"
    candidates_section = candidates_markdown(candidate_commits)

    <<~BODY
      ## Foundational flow major updates (stopgap)

      > **Auto-generated.** Review the candidates below. Remove non-major changes, fill in impact descriptions, and add any major changes missed by auto-detection.

      **AI Gateway range:** [`#{from_tag}...#{to_tag}`](#{diff_url})

      #{candidates_section.chomp}

      ---

      <details>
      <summary>#{other_count} other commits not flagged as foundational flow changes</summary>

      See full diff: #{diff_url}
      </details>
    BODY
  end

  def candidates_markdown(candidate_commits)
    return <<~MD if candidate_commits.empty?

      No foundational flow changes detected automatically.

      No major foundational flow updates in this release.
    MD

    commit_entries = candidate_commits.map do |commit|
      sha = commit['short_id'] || commit['id'][0..7]
      <<~MD
        - **#{escape_md(commit['title'])}**
          - What changed: <!-- TODO -->
          - Expected impact: <!-- TODO -->
          - Diff: [#{sha}](#{commit['web_url']})
      MD
    end

    "<!-- For each flow with a major change: fill in impact and remove others -->\n\n#{commit_entries.join("\n")}"
  end

  def create_issue(title, body)
    uri = URI("#{GITLAB_API}/projects/#{@dap_project_id}/issues")

    request = Net::HTTP::Post.new(uri)
    request['PRIVATE-TOKEN'] = @dap_token
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(
      title: title,
      description: body,
      labels: 'group::agent foundations,Duo Agent Platform'
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 30
      http.write_timeout = 30
      http.request(request)
    end

    raise "Failed to create issue (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPCreated)

    JSON.parse(response.body)
  end

  def api_get(uri, token:)
    request = Net::HTTP::Get.new(uri)
    request['PRIVATE-TOKEN'] = token

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 30
      http.write_timeout = 30
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      body_preview = response.body[0..500]
      raise "API request failed (#{response.code}): #{uri}\nResponse: #{body_preview}"
    end

    response
  end

  def escape_md(text)
    text.gsub(/([\\`*_\[\]])/, '\\\\\1')
  end

  def require_env(name)
    ENV.fetch(name) do
      raise "Missing required environment variable: #{name}"
    end
  end
end

DapFoundationalFlowsReleaseNotes.new.execute if $PROGRAM_NAME == __FILE__
