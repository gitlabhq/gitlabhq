# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/string'
require 'gitlab/housekeeper/logger'
require 'gitlab/housekeeper/keep'
require 'gitlab/housekeeper/keeps/rubocop_fixer'
require 'gitlab/housekeeper/gitlab_client'
require 'gitlab/housekeeper/git'
require 'gitlab/housekeeper/change'
require 'gitlab/housekeeper/substitutor'
require 'awesome_print'
require 'digest'

module Gitlab
  module Housekeeper
    class Runner
      def initialize(
        max_mrs: 1,
        dry_run: false,
        keeps: nil,
        filter_identifiers: [],
        push_when_approved: false,
        target_branch: 'master')
        @max_mrs = max_mrs
        @dry_run = dry_run
        @logger = Logger.new($stdout)
        @target_branch = target_branch
        @push_when_approved = push_when_approved
        require_keeps

        @keeps = if keeps
                   keeps.map { |k| k.is_a?(String) ? k.constantize : k }
                 else
                   all_keeps
                 end

        @filter_identifiers = filter_identifiers
      end

      def run
        mrs_created_count = 0

        git.with_clean_state do
          @keeps.each do |keep_class|
            @logger.puts "Running keep #{keep_class}"
            keep = keep_class.new(logger: @logger)
            keep.each_change do |change|
              unless change.valid?
                @logger.warn "Ignoring invalid change from: #{keep_class}"
                next
              end

              change.keep_class ||= keep_class

              branch_name = git.create_branch(change)
              add_standard_change_data(change)

              unless change.matches_filters?(@filter_identifiers)
                # At this point the keep has already run and edited files so we need to
                # restore the local working copy. We could simply checkout all
                # changed_files but this is very risky as it could mean losing work that
                # cannot be recovered. Instead we commit all the work to the branch and
                # move on without pushing the branch.
                git.in_branch(branch_name) do
                  git.create_commit(change)
                end

                @logger.puts "Skipping change: #{change.identifiers} due to not matching filter."
                @logger.puts "Modified files have been committed to branch #{branch_name.yellowish}," \
                             "but will not be pushed."
                @logger.puts

                next
              end

              # If no merge request exists yet, create an empty one to allow keeps to use the web URL.
              unless @dry_run
                merge_request = get_existing_merge_request(branch_name) || create(change, branch_name)

                change.mr_web_url = merge_request['web_url']
              end

              git.in_branch(branch_name) do
                Gitlab::Housekeeper::Substitutor.perform(change)

                git.create_commit(change)
              end

              print_change_details(change, branch_name)

              create(change, branch_name) unless @dry_run

              mrs_created_count += 1
              break if mrs_created_count >= @max_mrs
            end
            break if mrs_created_count >= @max_mrs
          end
        end

        print_completion_message(mrs_created_count)
      end

      def print_completion_message(mrs_created_count)
        mr_count_string = "#{mrs_created_count} #{'MR'.pluralize(mrs_created_count)}"

        completion_message = if @dry_run
                               "Dry run complete. Housekeeper would have created #{mr_count_string} on an actual run."
                             else
                               "Housekeeper created #{mr_count_string}."
                             end

        @logger.puts completion_message.yellowish
        @logger.puts
      end

      def add_standard_change_data(change)
        change.labels ||= []
        change.labels << 'automation:gitlab-housekeeper-authored'
      end

      def git
        @git ||= ::Gitlab::Housekeeper::Git.new(logger: @logger, branch_from: @target_branch)
      end

      def require_keeps
        Dir.glob("keeps/*.rb").each do |f|
          require(Pathname(f).expand_path.to_s)
        end
      end

      def print_change_details(change, branch_name)
        base_message = "Merge request URL: #{change.mr_web_url || '(known after create)'}, on branch #{branch_name}. " \
                       "Squash commits enabled."
        base_message << " CI skipped." if change.push_options.ci_skip

        @logger.puts base_message.yellowish
        @logger.puts "=> #{change.identifiers.join(': ')}".purple

        @logger.puts '=> Title:'.purple
        @logger.puts change.title.purple
        @logger.puts

        @logger.puts '=> Description:'
        @logger.puts change.description
        @logger.puts

        if change.labels.present? || change.assignees.present? || change.reviewers.present?
          @logger.puts '=> Attributes:'
          @logger.puts "Labels: #{change.labels.join(', ')}"
          @logger.puts "Assignees: #{change.assignees.join(', ')}"
          @logger.puts "Reviewers: #{change.reviewers.join(', ')}"
          @logger.puts
        end

        @logger.puts '=> Diff:'
        @logger.puts Shell.execute('git', '--no-pager', 'diff', '--color=always', @target_branch, branch_name, '--',
          *change.changed_files)
        @logger.puts
      end

      def create(change, branch_name)
        change.non_housekeeper_changes = gitlab_client.non_housekeeper_changes(
          source_project_id: housekeeper_fork_project_id,
          source_branch: branch_name,
          target_branch: @target_branch,
          target_project_id: housekeeper_target_project_id
        )

        git.push(branch_name, change.push_options) if self.class.should_push_code?(change, @push_when_approved)

        gitlab_client.create_or_update_merge_request(
          change: change,
          source_project_id: housekeeper_fork_project_id,
          source_branch: branch_name,
          target_branch: @target_branch,
          target_project_id: housekeeper_target_project_id
        )
      end

      def get_existing_merge_request(branch_name)
        gitlab_client.get_existing_merge_request(
          source_project_id: housekeeper_fork_project_id,
          source_branch: branch_name,
          target_branch: @target_branch,
          target_project_id: housekeeper_target_project_id
        )
      end

      # We do not want to push code if the MR already has approvals as it will reset the approvals. Also we do not push
      # if someone else has added commits already.
      def self.should_push_code?(change, push_when_approved)
        return false if change.already_approved? && !push_when_approved

        change.update_required?(:code)
      end

      def housekeeper_fork_project_id
        ENV.fetch('HOUSEKEEPER_FORK_PROJECT_ID', housekeeper_target_project_id)
      end

      def housekeeper_target_project_id
        ENV.fetch('HOUSEKEEPER_TARGET_PROJECT_ID')
      end

      def gitlab_client
        @gitlab_client ||= GitlabClient.new
      end

      def all_keeps
        @all_keeps ||= ObjectSpace.each_object(Class).select { |klass| klass < Keep }
      end
    end
  end
end
