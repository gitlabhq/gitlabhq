#!/usr/bin/env ruby

# frozen_string_literal: true

#
# https://docs.gitlab.com/development/documentation/redirects/
#
require 'net/http'
require 'uri'
require 'json'
require 'cgi'
require 'yaml'

class LintDocsRedirect
  COLOR_CODE_RED = "\e[31m"
  COLOR_CODE_RESET = "\e[0m"
  # All the projects we want this script to run
  PROJECT_PATHS = ['gitlab-org/gitlab',
    'gitlab-org/gitlab-runner',
    'gitlab-org/omnibus-gitlab',
    'gitlab-org/charts/gitlab',
    'gitlab-org/cloud-native/gitlab-operator'].freeze

  def execute
    return unless project_supported?

    abort_unless_merge_request_iid_exists

    check_renamed_deleted_files
    check_for_circular_redirects
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
    end
  end

  # Location of docs files in the project
  def docs_path
    ENV['CI_PROJECT_PATH'] == 'gitlab-org/gitlab-runner' ? 'docs/' : 'doc/'
  end

  def navigation_file
    @navigation_file ||= begin
      # Temporary handling for multiple navigation locations.
      # The navigation YAML file will move when this merges:
      # https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/merge_requests/307.
      #
      # We are not able to control these changes merging at exactly the same time,
      # so this temporarily supports both the new and old file location.
      url = URI('https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/raw/main/data/en-us/navigation.yaml')
      response = Net::HTTP.get_response(url)

      # If new URL fails, try the old URL
      if response.code != '200'
        url = URI('https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/raw/main/data/navigation.yaml')
        response = Net::HTTP.get_response(url)

        raise "Could not download navigation.yaml. Response code: #{response.code}" if response.code != '200'
      end

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
    # Translate the file path to its website path:
    # 1. gsub(docs_path, project_slug) - Replaces the local docs directory with the appropriate project URL prefix
    # 2. gsub(/_?index\.md/, '') - Removes both index.md and _index.md
    # 3. gsub('.md', '/') - Converts .md to a trailing slash
    file_sub = file["old_path"]
      .gsub(docs_path, project_slug)
      .gsub(/_?index\.md/, '')
      .gsub('.md', '/')

    result = navigation_file.include?("'#{file_sub}'")
    return unless result

    # If we're here, the path exists in navigation
    # Now check if this is a rename between index.md and _index.md
    if renamed_doc_file?(file)
      old_basename = File.basename(file['old_path'])
      new_basename = File.basename(file['new_path'])

      # Allow renames between index.md and _index.md
      return if %w[index.md _index.md].include?(old_basename) &&
        %w[index.md _index.md].include?(new_basename)

      # Handle the case where page.md is moved to page/_index.md
      if !old_basename.start_with?('_') &&
          new_basename == '_index.md' &&
          File.dirname(file['old_path']) == File.dirname(File.dirname(file['new_path']))
        # The path structure looks like:
        # old: doc/path/page.md
        # new: doc/path/page/_index.md
        return
      end
    end

    warning(file)

    abort
  end

  def warning(file)
    warn <<~WARNING
      #{COLOR_CODE_RED}✖ ERROR: Missing redirect for a deleted or moved page#{COLOR_CODE_RESET}

      The following file is linked in the global navigation for docs.gitlab.com:

      => #{file['old_path']}

      Unless you add a redirect or remove the page from the global navigation,
      this change will break pipelines in the
      https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com project.

      #{rake_command(file)}

      For more information, see:
      - Create a redirect   : https://docs.gitlab.com/development/documentation/redirects/
      - Edit the global nav : https://docs.gitlab.com/development/documentation/site_architecture/global_nav/#add-a-navigation-entry
    WARNING
  end

  # Rake task to use depending on the file being deleted or renamed
  def rake_command(file)
    # The Rake task is only available for gitlab-org/gitlab
    return unless ENV['CI_PROJECT_PATH'] == 'gitlab-org/gitlab'

    if renamed_doc_file?(file)
      rake = "bundle exec rake \"gitlab:docs:redirect[#{file['old_path']}, #{file['new_path']}]\""
      msg = "It seems you renamed a page, run the following Rake task locally and commit the changes.\n"
    elsif deleted_doc_file?(file)
      rake = "bundle exec rake \"gitlab:docs:redirect[#{file['old_path']}, doc/new/path.md]\""
      msg = "It seems you deleted a page. Run the following Rake task by replacing\n" \
            "'doc/new/path.md' with the page to redirect to, and commit the changes.\n"
    end

    <<~MSG
      #{msg}
      #{rake}
    MSG
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
    abort("Error: CI_MERGE_REQUEST_IID environment variable is missing") if merge_request_iid.nil?
  end

  # Skip if CI_PROJECT_PATH is not in the designated project paths
  def project_supported?
    PROJECT_PATHS.include? ENV['CI_PROJECT_PATH']
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
    renamed_files = merge_request_diff.select do |file|
      renamed_doc_file?(file)
    end

    deleted_files = merge_request_diff.select do |file|
      deleted_doc_file?(file)
    end

    # Merge the two arrays
    all_files = renamed_files + deleted_files

    return if all_files.empty?

    all_files.each do |file|
      status = deleted_doc_file?(file) ? 'deleted' : 'renamed'
      puts "Checking #{status} file..."
      puts "=> Old_path: #{file['old_path']}"
      puts "=> New_path: #{file['new_path']}"
      puts

      check_for_missing_nav_entry(file)
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
    all_doc_files.each do |file|
      next if redirect_to(file).nil?

      basename = File.basename(file['old_path'])

      # Fail if the 'redirect_to' value is the same as the file's basename.
      next unless redirect_to(file) == basename

      warn <<~WARNING
        #{COLOR_CODE_RED}✖ ERROR: Circular redirect detected. The 'redirect_to' value points to the same file.#{COLOR_CODE_RESET}
      WARNING

      puts
      puts "File        : #{file['old_path']}"
      puts "Redirect to : #{redirect_to(file)}"

      abort
    end
  end
end

LintDocsRedirect.new.execute if $PROGRAM_NAME == __FILE__
