# frozen_string_literal: true

require 'fileutils'
require 'cgi'

require_relative '../config/environment'
require_relative 'helpers/groups'
require_relative 'helpers/milestones'
require_relative 'helpers/git_diff_parser'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will locate any feature flag definition file
  # that were added at least `<CUTOFF_MILESTONE_OLD> milestones` ago and remove the definition file.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::DeleteOldFeatureFlags
  # ```
  class DeleteOldFeatureFlags < ::Gitlab::Housekeeper::Keep
    CUTOFF_MILESTONE_OLD = 12
    GREP_IGNORE = [
      'locale/',
      'db/structure.sql'
    ].freeze
    ROLLOUT_ISSUE_URL_REGEX = %r{\Ahttps://gitlab\.com/(?<project_path>.*)/-/issues/(?<issue_iid>\d+)\z}
    API_ISSUE_URL = "https://gitlab.com/api/v4/projects/%<project_path>s/issues/%<issue_iid>s"
    FEATURE_FLAG_LOG_ISSUES_URL = "https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues/?search=%<feature_flag_name>s&sort=created_date&state=all&label_name%%5B%%5D=host%%3A%%3Agitlab.com"

    def each_change
      each_feature_flag do |feature_flag|
        change = prepare_change(feature_flag)

        yield(change) if change
      end
    end

    private

    def prepare_change(feature_flag)
      if feature_flag.milestone.nil?
        @logger.puts "#{feature_flag.name} has no milestone set!"
        return
      end

      return unless milestones_helper.before_cuttoff?(
        milestone: feature_flag.milestone,
        milestones_ago: CUTOFF_MILESTONE_OLD)

      change = ::Gitlab::Housekeeper::Change.new
      change.changelog_type = 'removed'
      change.title = "Delete the `#{feature_flag.name}` feature flag"
      change.identifiers = [self.class.name.demodulize, feature_flag.name]

      FileUtils.rm(feature_flag.path)

      change.changed_files = [feature_flag.path]

      apply_patch_and_cleanup(feature_flag, change)

      # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- Not running inside rails application
      change.description = <<~MARKDOWN
      This feature flag was introduced in #{feature_flag.milestone}, which is more than #{CUTOFF_MILESTONE_OLD} milestones ago.

      As part of our process we want to ensure [feature flags don't stay too long in the codebase](https://docs.gitlab.com/ee/development/feature_flags/#types-of-feature-flags).

      Rollout issue: #{feature_flag_rollout_issue_url(feature_flag)}

      #{feature_flag_default_enabled_note(feature_flag.default_enabled)}

      <details><summary>Remaining mentions of the feature flag (click to expand)</summary>

      ```
      #{feature_flag_grep(feature_flag.name)}
      ```

      </details>

      It is possible that this MR will still need some changes to remove references to the feature flag in the code.
      At the moment the `gitlab-housekeeper` is not always capable of removing all references so you must check the diff and pipeline failures to confirm if there are any issues.
      It is the responsibility of ~"#{feature_flag.group}" to push those changes to this branch.
      If they are already removing this feature flag in another merge request then they can just close this merge request.

      You can also see the status of the rollout by checking #{feature_flag_rollout_issue_url(feature_flag)} and #{format(FEATURE_FLAG_LOG_ISSUES_URL, feature_flag_name: feature_flag.name)}.
      MARKDOWN
      # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl

      change.labels = [
        'maintenance::removal',
        'feature flag',
        feature_flag.group
      ]

      change.reviewers = assignees(feature_flag.rollout_issue_url)

      if change.reviewers.empty?
        group_data = groups_helper.group_for_group_label(feature_flag.group)

        change.reviewers = groups_helper.pick_reviewer(group_data, change.identifiers) if group_data
      end

      change
    end

    def feature_flag_default_enabled_note(feature_flag_default_enabled)
      if feature_flag_default_enabled
        <<~NOTE
        The feature flag is enabled by default. Unless it's disabled on GitLab.com, you should keep the feature-flag
        code branch, otherwise, keep the other branch.
        NOTE
      else
        <<~NOTE
        The feature flag isn't enabled by default. If it's enabled on GitLab.com, you should keep the feature-flag
        code branch, otherwise, keep the other branch.
        NOTE
      end
    end

    def feature_flag_grep(feature_flag_name)
      Gitlab::Housekeeper::Shell.execute(
        'git',
        'grep',
        '--heading',
        '--line-number',
        '--break',
        feature_flag_name,
        '--',
        *(GREP_IGNORE.map { |path| ":^#{path}" })
      )
    rescue ::Gitlab::Housekeeper::Shell::Error
      # git grep returns error status if nothing is found
    end

    def apply_patch_and_cleanup(feature_flag, change)
      return unless patch_exists?(feature_flag)

      change.changed_files << patch_path(feature_flag)
      change.changed_files += extract_changed_files_from_patch(feature_flag)

      apply_patch(feature_flag)
      FileUtils.rm(patch_path(feature_flag))
    end

    def patch_exists?(feature_flag)
      File.file?(patch_path(feature_flag))
    end

    def apply_patch(feature_flag)
      Gitlab::Housekeeper::Shell.execute('git', 'apply', patch_path(feature_flag))
    end

    def patch_path(feature_flag)
      feature_flag.path.sub(/.yml$/, '.patch')
    end

    def extract_changed_files_from_patch(feature_flag)
      git_diff_parser_helper.all_changed_files(File.read(patch_path(feature_flag)))
    end

    def feature_flag_rollout_issue_url(feature_flag)
      feature_flag.rollout_issue_url || '(missing URL)'
    end

    def assignees(rollout_issue_url)
      rollout_issue = get_rollout_issue(rollout_issue_url)

      return unless rollout_issue && rollout_issue[:assignees]

      rollout_issue[:assignees]
    end

    def get_rollout_issue(rollout_issue_url)
      matches = ROLLOUT_ISSUE_URL_REGEX.match(rollout_issue_url)
      return unless matches

      response = Gitlab::HTTP_V2.try_get( # rubocop:disable Gitlab/HttpV2 -- Not running inside rails application
        format(API_ISSUE_URL, project_path: CGI.escape(matches[:project_path]), issue_iid: matches[:issue_iid])
      )

      unless (200..299).cover?(response.code)
        raise Error,
          "Failed with response code: #{response.code} and body:\n#{response.body}"
      end

      Gitlab::Json.parse(response.body, symbolize_names: true)
    end

    def each_feature_flag
      all_feature_flag_files.map do |f|
        yield(
          Feature::Definition.new(f, YAML.safe_load_file(f, permitted_classes: [Symbol], symbolize_names: true))
        )
      end
    end

    def all_feature_flag_files
      Dir.glob("{,ee/}config/feature_flags/{development,gitlab_com_derisk}/*.yml")
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def milestones_helper
      @milestones_helper ||= ::Keeps::Helpers::Milestones.new
    end

    def git_diff_parser_helper
      @git_diff_parser_helper ||= ::Keeps::Helpers::GitDiffParser.new
    end
  end
end
