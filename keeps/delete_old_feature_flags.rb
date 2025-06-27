# frozen_string_literal: true

require 'fileutils'
require 'cgi'

require_relative '../config/environment'
require_relative 'helpers/groups'
require_relative 'helpers/milestones'
require_relative 'helpers/git_diff_parser'
require_relative 'helpers/ai_editor'
require_relative 'prompts/remove_feature_flags'

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
    CUTOFF_MILESTONE_FOR_DISABLED_FLAG = 12
    CUTOFF_MILESTONE_FOR_ENABLED_FLAG = 4
    Error = Class.new(StandardError)
    GREP_IGNORE = [
      'locale/',
      'db/structure.sql'
    ].freeze
    ROLLOUT_ISSUE_URL_REGEX = %r{\Ahttps://gitlab\.com/(?<project_path>.*)/-/issues/(?<issue_iid>\d+)\z}
    API_ISSUE_URL = "https://gitlab.com/api/v4/projects/%<project_path>s/issues/%<issue_iid>s"
    FEATURE_FLAG_LOG_ISSUES_URL = "https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues/?search=%<feature_flag_name>s&sort=created_date&state=all&label_name%%5B%%5D=host%%3A%%3Agitlab.com"
    MISSING_URL_PLACEHOLDER = '(missing URL)'

    def each_change
      each_feature_flag do |feature_flag|
        change = prepare_change(feature_flag)

        yield(change) if change
      end
    end

    private

    def parse_date(date_string)
      Date.parse(date_string)
    rescue Date::Error
      nil
    end

    def can_remove_ff?(feature_flag, identifiers, latest_feature_flag_status)
      return false unless valid_feature_flag_status?(feature_flag, latest_feature_flag_status)

      # Check if feature flag has ready for removal label - this bypasses most validation checks
      if has_ready_for_removal_label?(feature_flag)
        @logger.puts "#{feature_flag.name} has 'feature flag::ready for removal' label, bypassing validation checks"
        return true
      end

      return false unless valid_rollout_date?(feature_flag)
      return false unless valid_milestone?(feature_flag)
      return false unless within_milestone_cutoff?(feature_flag, latest_feature_flag_status)
      return false unless matches_filter_identifiers?(identifiers)

      true
    end

    def valid_rollout_date?(feature_flag)
      intended_to_rollout_by_date = feature_flag.intended_to_rollout_by
      return true unless intended_to_rollout_by_date.present?

      rollout_date = parse_date(intended_to_rollout_by_date)
      if rollout_date.nil?
        message = "#{feature_flag.name} intended_to_rollout_by #{intended_to_rollout_by_date}"
        @logger.puts "#{message}, is ignored as it cannot be parsed."
      elsif rollout_date.future?
        @logger.puts "#{feature_flag.name} cannot be removed, intended rollout date is #{intended_to_rollout_by_date}"
        return false
      end

      true
    end

    def valid_milestone?(feature_flag)
      return true unless feature_flag.milestone.nil?

      @logger.puts "#{feature_flag.name} has no milestone set!"
      false
    end

    def valid_feature_flag_status?(feature_flag, latest_feature_flag_status)
      if latest_feature_flag_status.nil?
        @logger.puts "#{feature_flag.name} cannot be removed as we cannot get the status from the rollout issue."
        return false
      end

      if latest_feature_flag_status == :conditional
        @logger.puts "#{feature_flag.name} cannot be removed as it is partially rolled out."
        return false
      end

      true
    end

    def within_milestone_cutoff?(feature_flag, latest_feature_flag_status)
      cutoff = if latest_feature_flag_status == :disabled
                 CUTOFF_MILESTONE_FOR_DISABLED_FLAG
               else
                 CUTOFF_MILESTONE_FOR_ENABLED_FLAG
               end

      return true if milestones_helper.before_cuttoff?(milestone: feature_flag.milestone, milestones_ago: cutoff)

      @logger.puts "#{feature_flag.name} cannot be removed as it is after the cutoff."
      false
    end

    # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- Not running inside rails application
    def build_description(feature_flag, latest_feature_flag_status)
      ready_for_removal = has_ready_for_removal_label?(feature_flag)

      introduction_text = if ready_for_removal
                            "This feature flag was introduced in #{feature_flag.milestone} and has been " \
                              "marked as ready for removal with the `~\"feature flag::ready for removal\"` " \
                              "label, bypassing the standard milestone cutoff requirements."
                          else
                            cutoff_count = if latest_feature_flag_status == :enabled
                                             CUTOFF_MILESTONE_FOR_ENABLED_FLAG
                                           else
                                             CUTOFF_MILESTONE_FOR_DISABLED_FLAG
                                           end

                            "This feature flag was introduced in #{feature_flag.milestone}, which is " \
                              "more than #{cutoff_count} milestones ago."
                          end

      <<~MARKDOWN
      #{introduction_text}

      As part of our process we want to ensure [feature flags don't stay too long in the codebase](https://docs.gitlab.com/ee/development/feature_flags/#types-of-feature-flags).

      Rollout issue: #{feature_flag_rollout_issue_url(feature_flag)}

      <details><summary>Remaining mentions of the feature flag (click to expand)</summary>

      ```
      #{feature_flag_grep(feature_flag.name)}
      ```

      </details>

       **Currently the feature flag is `#{latest_feature_flag_status}` on production**

      It is possible that this MR will still need some changes to remove references to the feature flag in the code.
      At the moment the `gitlab-housekeeper` is not always capable of removing all references so you must check the diff and pipeline failures to confirm if there are any issues.
      It is the responsibility of ~"#{feature_flag.group}" to push those changes to this branch.

      **Note:** If you do not want to remove this feature flag at this time, you can add an `intended_to_rollout_by_date` attribute in the feature flag YAML file to prevent automated removal.

      ## TODO for the reviewers before merging this MR
      - [ ] See the status of the rollout by checking #{feature_flag_rollout_issue_url(feature_flag)}, #{format(FEATURE_FLAG_LOG_ISSUES_URL, feature_flag_name: feature_flag.name)}
      - [ ] Verify the feature flag status via chatops by running `/chatops run feature get #{feature_flag.name}`.
      - [ ] [Search for references to `#{feature_flag.name.split('_').map(&:capitalize).join}` in frontend part of code](https://gitlab.com/search?project_id=278964&scope=blobs&search=#{feature_flag.name.split('_').map(&:capitalize).join}&regex=false)
      - [ ] [Search for references to `#{feature_flag.name}` in code](https://gitlab.com/search?project_id=278964&scope=blobs&search=#{feature_flag.name}&regex=false)
      - [ ] Check if we need to remove any Gem or other related code by looking at the changes in #{feature_flag.introduced_by_url}
      MARKDOWN
    end
    # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl

    def prepare_change(feature_flag)
      identifiers = [self.class.name.demodulize, feature_flag.name]
      latest_feature_flag_status = get_latest_feature_flag_status(feature_flag)
      return unless can_remove_ff?(feature_flag, identifiers, latest_feature_flag_status)

      change = ::Gitlab::Housekeeper::Change.new
      change.changelog_type = 'removed'
      change.title = "Delete the `#{feature_flag.name}` feature flag"
      change.identifiers = identifiers
      change.description = build_description(feature_flag, latest_feature_flag_status)

      FileUtils.rm(feature_flag.path)
      change.changed_files = [feature_flag.path]

      applied = apply_patch_or_ask_ai(feature_flag, change)

      unless applied
        @logger.puts "#{feature_flag.name} aborting because change not applied."
        @logger.puts "Change #{change.to_json}"
        change.abort!
        return change
      end

      change.labels = [
        'automation:feature-flag-removal',
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

    def feature_flag_grep(feature_flag_name)
      all_results = ''

      git_patterns(feature_flag_name).each do |pattern|
        result = execute_grep(pattern)
        all_results += "#{result}\n" if result.present?
      end

      all_results.empty? ? nil : all_results
    end

    def execute_grep(pattern)
      Gitlab::Housekeeper::Shell.execute(
        'git',
        'grep',
        '--heading',
        '--line-number',
        '--break',
        pattern,
        '--',
        *(GREP_IGNORE.map { |path| ":^#{path}" })
      )
    rescue ::Gitlab::Housekeeper::Shell::Error
      # git grep returns error status if nothing is found
      ""
    end

    def ai_patch(feature_flag, change)
      failed_files = []

      files_mentioning_feature_flag(feature_flag.name).each do |file|
        flag_enabled = get_latest_feature_flag_status(feature_flag) == :enabled
        user_message = remove_feature_flag_prompts.fetch(feature_flag, file, flag_enabled)

        unless user_message
          @logger.puts "#{feature_flag.name}: No prompt generated for #{file}, skipping"
          next
        end

        applied = ai_helper.ask_for_and_apply_patch(user_message, file)

        unless applied
          @logger.puts "#{feature_flag.name}: Failed to apply AI patch for #{file}, skipping"
          failed_files << file
          next
        end

        begin
          ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(file) unless file.end_with?('.vue', '.js')
        rescue ::Gitlab::Housekeeper::Shell::Error => e
          @logger.puts "#{feature_flag.name}: Rubocop error for #{file}, but continuing: #{e.message}"
        end

        change.changed_files << file
      end

      if failed_files.any?
        @logger.puts "failed on #{failed_files.size} files"
        @logger.puts "Failed files: #{failed_files.join(', ')}"
      end

      failed_files.empty?
    end

    def apply_patch_or_ask_ai(feature_flag, change)
      return apply_patch(feature_flag, change) if patch_exists?(feature_flag)

      ai_patch(feature_flag, change)
    end

    def apply_patch(feature_flag, change)
      change.changed_files << patch_path(feature_flag)
      change.changed_files += extract_changed_files_from_patch(feature_flag)

      begin
        Gitlab::Housekeeper::Shell.execute('git', 'apply', patch_path(feature_flag))
      rescue ::Gitlab::Housekeeper::Shell::Error
        @logger.puts "#{patch_path(feature_flag)} git apply error"
        return false
      end

      FileUtils.rm(patch_path(feature_flag))
      true
    end

    def patch_exists?(feature_flag)
      File.file?(patch_path(feature_flag))
    end

    def patch_path(feature_flag)
      feature_flag.path.sub(/.yml$/, '.patch')
    end

    def extract_changed_files_from_patch(feature_flag)
      git_diff_parser_helper.all_changed_files(File.read(patch_path(feature_flag)))
    end

    def feature_flag_rollout_issue_url(feature_flag)
      feature_flag.rollout_issue_url || MISSING_URL_PLACEHOLDER
    end

    def assignees(rollout_issue_url)
      rollout_issue = get_rollout_issue(rollout_issue_url)

      return unless rollout_issue && rollout_issue[:assignees]

      rollout_issue[:assignees].pluck(:username) # rubocop:disable CodeReuse/ActiveRecord -- We need to collect the usernames from array of hashes.
    end

    def get_rollout_issue(rollout_issue_url)
      matches = ROLLOUT_ISSUE_URL_REGEX.match(rollout_issue_url)
      return unless matches

      # rubocop:disable Gitlab/HttpV2 -- Not running inside rails application
      response = Gitlab::HTTP_V2.try_get(
        format(API_ISSUE_URL, project_path: CGI.escape(matches[:project_path]), issue_iid: matches[:issue_iid])
      )
      # rubocop:enable Gitlab/HttpV2

      unless response.success?
        @logger.puts(
          "Get URL: #{rollout_issue_url} Failed with response code: #{response.code} and body:\n#{response.body}"
        )
        return
      end

      Gitlab::Json.parse(response.body, symbolize_names: true)
    end

    def has_ready_for_removal_label?(feature_flag)
      rollout_issue_url = feature_flag_rollout_issue_url(feature_flag)
      return false if rollout_issue_url == MISSING_URL_PLACEHOLDER

      rollout_issue = get_rollout_issue(rollout_issue_url)
      return false unless rollout_issue

      rollout_issue[:labels].any?('feature flag::ready for removal')
    rescue StandardError => e
      @logger.puts "Error checking ready for removal label for #{feature_flag.name}: #{e.message}"
      false
    end

    def get_latest_feature_flag_status(feature_flag)
      return :enabled if feature_flag.default_enabled

      rollout_issue_url = feature_flag_rollout_issue_url(feature_flag)
      if rollout_issue_url == MISSING_URL_PLACEHOLDER
        @logger.puts "Can't fetch ff status for #{feature_flag.name} due to absence of rollout issue."
        return
      end

      rollout_issue = get_rollout_issue(rollout_issue_url)
      return unless rollout_issue

      state_label = rollout_issue[:labels].find { |label| label.start_with?('feature flag state::') }

      if state_label.nil?
        @logger.puts(
          "Can't fetch ff status for #{feature_flag.name} due to absence of feature flag state label on rollout issue."
        )
        return
      end

      case state_label
      when 'feature flag state::enabled'
        :enabled
      when 'feature flag state::disabled'
        :disabled
      when 'feature flag state::rolling out'
        :conditional
      end
    end

    def each_feature_flag
      all_feature_flag_files.map do |f|
        feature_definition = Feature::Definition.new(f,
          YAML.safe_load_file(f, permitted_classes: [Symbol], symbolize_names: true))

        yield(feature_definition)
      end
    end

    def all_feature_flag_files
      Dir.glob("{,ee/}config/feature_flags/{development,gitlab_com_derisk,beta}/*.yml")
    end

    def remove_feature_flag_prompts
      @remove_feature_flag_prompts ||= ::Keeps::Prompts::RemoveFeatureFlags.new(@logger)
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

    def ai_helper
      ::Keeps::Helpers::AiEditor.new
    end

    def git_patterns(feature_flag_name)
      camel_case_flag = feature_flag_name.camelize(:lower)
      [
        "feature.*#{feature_flag_name}",
        "push_frontend_feature_flag.*#{feature_flag_name}",
        "glFeatures.*#{camel_case_flag}",
        "gon.*#{camel_case_flag}",
        camel_case_flag,
        feature_flag_name
      ]
    end

    def files_mentioning_feature_flag(feature_flag_name)
      all_files = []

      git_patterns(feature_flag_name).each do |pattern|
        result = find_files_with_pattern(pattern)
        all_files += result if result.any?
      end

      @logger.puts "All files mentioning feature flag #{feature_flag_name}"
      all_files.uniq
    end

    def find_files_with_pattern(pattern)
      result = Gitlab::Housekeeper::Shell.execute(
        'git',
        'grep',
        '--name-only',
        pattern,
        '--',
        *(GREP_IGNORE.map { |path| ":^#{path}" })
      )

      return [] if result.blank?

      result.split("\n")
    rescue ::Gitlab::Housekeeper::Shell::Error
      @logger.puts "No files found for pattern: #{pattern}" if @logger
      []
    end
  end
end
