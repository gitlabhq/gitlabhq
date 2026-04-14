#!/usr/bin/env ruby
# frozen_string_literal: true

# For more information, see https://docs.gitlab.com/development/documentation/redirects/
require 'net/http'
require 'uri'
require 'json'
require 'cgi'
require 'yaml'

class LintDocsRedirect
  COLOR_CODE_RED = "\e[1;31m"
  COLOR_CODE_GREEN = "\e[1;32m"
  COLOR_CODE_RESET = "\e[0m"
  # Script only supports these projects
  PROJECT_PATHS = ['gitlab-org/gitlab',
    'gitlab-org/gitlab-runner',
    'gitlab-org/omnibus-gitlab',
    'gitlab-org/charts/gitlab',
    'gitlab-org/cloud-native/gitlab-operator',
    'gitlab-org/cli'].freeze

  def execute
    puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Checking documentation redirects..."
    return unless project_supported?

    abort_unless_merge_request_iid_exists unless ENV['CI']

    @errors = false
    check_renamed_deleted_files
    check_for_circular_redirects

    if @errors
      puts "#{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} Check of documentation redirects complete with errors!"
      abort
    else
      puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Check of documentation redirects complete with no errors."
    end
  end

  private

  # Website root path based on project path
  def project_slug
    case ENV['CI_PROJECT_PATH']
    when 'gitlab-org/gitlab'
      ''
    when 'gitlab-org/gitlab-runner'
      'runner'
    when 'gitlab-org/omnibus-gitlab'
      'omnibus'
    when 'gitlab-org/charts/gitlab'
      'charts'
    when 'gitlab-org/cloud-native/gitlab-operator'
      'operator'
    when 'gitlab-org/cli'
      'cli'
    end
  end

  # Location of docs files in the project
  def docs_path
    case ENV['CI_PROJECT_PATH']
    when 'gitlab-org/gitlab-runner'
      'docs/'
    when 'gitlab-org/cli'
      'docs/source'
    else
      'doc/'
    end
  end

  def navigation_file
    @navigation_file ||= begin
      url = URI('https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/raw/main/data/en-us/navigation.yaml')
      response = Net::HTTP.get_response(url)

      raise "Could not download navigation.yaml. Response code: #{response.code}" if response.code != '200'

      # response.body should be memoized in a method, so that it doesn't
      # need to be downloaded multiple times in one CI job.
      response.body
    end
  end

  ##
  ## Check if the deleted/renamed file exists in
  ## https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/data/navigation.yaml.
  ##
  ## We need to first convert the Markdown file path to HTML. There are two cases:
  ##
  ## - A source doc entry with _index.md looks like: doc/administration/_index.md
  ##   The navigation.yaml equivalent is:           administration/
  ## - A source doc entry without _index.md looks like: doc/administration/appearance.md
  ##   The navigation.yaml equivalent is:              administration/appearance/
  ##
  def check_for_missing_nav_entry(file)
    puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Checking for navigation entry to file..."
    # Translate the file path to its website path:
    # 1. gsub(docs_path, project_slug) - Replaces the local docs directory with the appropriate project URL prefix
    # 2. gsub(/_?index\.md/, '') - Removes both index.md and _index.md
    # 3. gsub('.md', '/') - Converts .md to a trailing slash
    file_sub = file["old_path"]
      .gsub(docs_path, project_slug)
      .gsub(/_?index\.md/, '')
      .gsub('.md', '/')

    result = navigation_file.include?("'#{file_sub}'")

    if result
      puts <<~ERROR
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} File #{file['old_path']} has a navigation entry: #{file_sub}!
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} You must either add a redirect for the page or remove the page from the global navigation!
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} For more information, see:
              - https://docs.gitlab.com/development/documentation/redirects/
              - https://docs.gitlab.com/development/documentation/site_architecture/global_nav/#add-a-navigation-entry
      ERROR
      @errors = true
    else
      puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} No navigation entry for file #{file['old_path']} found."
    end
  end

  # When renaming files, we can't have either:
  #   - file.md renamed to file/_index.md
  #   - file/_index.md renamed to file.md
  # This situation causes Hugo build errors because both paths will publish to the same URL.
  def check_for_invalid_rename(file)
    puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Checking if file #{file['old_path']} is invalidly renamed..."

    if file['old_path'].delete_suffix('.md') == file['new_path'].delete_suffix('/_index.md') ||
        file['old_path'].delete_suffix('/_index.md') == file['new_path'].delete_suffix('.md')
      puts <<~ERROR
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} File #{file['old_path']} is invalidly renamed!
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} The file #{file['old_path']} must not be renamed to #{file['new_path']}!
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} Choose an alternative name for the new file!
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} For more information, see: https://docs.gitlab.com/development/documentation/redirects/#troubleshooting
      ERROR
      @errors = true
    else
      puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} File is validly renamed."
    end
  end

  # GitLab API URL
  def gitlab_api_url
    ENV.fetch('CI_API_V4_URL', 'https://gitlab.com/api/v4')
  end

  # Take the project path from the CI_PROJECT_PATH predefined variable.
  def url_encoded_project_path
    project_path = ENV.fetch('CI_PROJECT_PATH', nil)
    return unless project_path

    CGI.escape(project_path)
  end

  # Take the merge request ID from the CI_MERGE_REQUEST_IID predefined
  # variable.
  def merge_request_iid
    ENV.fetch('CI_MERGE_REQUEST_IID', nil)
  end

  def abort_unless_merge_request_iid_exists
    if merge_request_iid
      puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} CI_MERGE_REQUEST_IID environment variable is set."
    else
      abort <<~ERROR
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} CI_MERGE_REQUEST_IID environment variable is not set!
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} You must run the script against an existing merge request!
      ERROR
    end
  end

  # Skip if CI_PROJECT_PATH is not in the designated project paths
  def project_supported?
    if !ENV['CI_PROJECT_PATH']
      abort <<~ERROR
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} CI_PROJECT_PATH environment variable is not set!
        #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} Must be one of: #{PROJECT_PATHS.join(', ')}!
      ERROR
    elsif PROJECT_PATHS.none?(ENV['CI_PROJECT_PATH'])
      abort "#{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} CI_PROJECT_PATH of #{ENV['CI_PROJECT_PATH']} is not supported!"
    end

    puts <<~INFO
      #{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Running in supported project.
    INFO
    true
  end

  # Fetch the merge request diff JSON object
  def merge_request_diff
    @merge_request_diff ||= begin
      uri = URI.parse(
        "#{gitlab_api_url}/projects/#{url_encoded_project_path}/merge_requests/#{merge_request_iid}/diffs?per_page=30"
      )
      response = Net::HTTP.get_response(uri)

      unless response.code == '200'
        raise "API call to get MR diffs failed. Response code: #{response.code}. Response message: #{response.message}"
      end

      JSON.parse(response.body)
    end
  end

  def doc_file?(file)
    file['old_path'].start_with?('doc/') && file['old_path'].end_with?('.md')
  end

  def renamed_doc_file?(file)
    file['renamed_file'] == true && doc_file?(file)
  end

  def deleted_doc_file?(file)
    file['deleted_file'] == true && doc_file?(file)
  end

  # Create a list of hashes of the renamed documentation files
  def check_renamed_deleted_files
    puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Checking for renamed or deleted files..."
    renamed_files = merge_request_diff.select do |file|
      renamed_doc_file?(file)
    end

    deleted_files = merge_request_diff.select do |file|
      deleted_doc_file?(file)
    end

    # Merge the two arrays
    all_files = renamed_files + deleted_files

    if all_files.empty?
      puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} No renamed or deleted files found."
      return
    end

    all_files.each do |file|
      status = deleted_doc_file?(file) ? 'deleted' : 'renamed'

      if status == 'renamed'
        puts <<~INFO
          #{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Found #{status} file #{file['old_path']}. File is being renamed to #{file['new_path']}.
        INFO
        check_for_invalid_rename(file)
      else
        puts <<~INFO
          #{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Found #{status} file #{file['old_path']}. File #{file['old_path']} is being deleted.
        INFO
        check_for_missing_nav_entry(file)
      end
    end
  end

  # Search for '+redirect_to' in the diff to find the new value. It should
  # return a string of "+redirect_to: 'file.md'", in which case, delete the
  # '+' prefix. If not found, skip and go to next file.
  def redirect_to(diff_file)
    redirect_to = diff_file["diff"]
                    .lines
                    .find { |e| e.include?('+redirect_to') }
                    &.delete_prefix('+')

    return if redirect_to.nil?

    YAML.safe_load(redirect_to)['redirect_to']
  end

  def all_doc_files
    merge_request_diff.select do |file|
      doc_file?(file)
    end
  end

  # Check if a page redirects to itself
  def check_for_circular_redirects
    puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Checking for pages that redirect to themselves..."
    all_doc_files.each do |file|
      next if redirect_to(file).nil?

      puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} Checking redirection in file #{file['old_path']}..."
      basename = File.basename(file['old_path'])

      # Fail if the 'redirect_to' value is the same as the file's basename.
      if redirect_to(file) == basename
        puts <<~ERROR
          #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} Circular redirect detected in file #{file['old_path']}!
          #{COLOR_CODE_RED}ERROR#{COLOR_CODE_RESET} The 'redirect_to' value of #{redirect_to(file)} in #{file['old_path']} points to #{file['old_path']}!
        ERROR
        @errors = true
      else
        puts "#{COLOR_CODE_GREEN}INFO#{COLOR_CODE_RESET} File #{file['old_path']} redirects to another file."
      end
    end
  end
end

LintDocsRedirect.new.execute if $PROGRAM_NAME == __FILE__
