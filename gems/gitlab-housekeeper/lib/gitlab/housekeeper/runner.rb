# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/string'
require 'gitlab/housekeeper/logger'
require 'gitlab/housekeeper/keep'
require 'gitlab/housekeeper/git'
require 'gitlab/housekeeper/change'
require 'gitlab/housekeeper/merge_request_manager'
require 'gitlab/housekeeper/substitutor'
require 'gitlab/housekeeper/filter_identifiers'
require 'amazing_print'
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
        push_when_conflict: true,
        target_branch: 'master')
        @max_mrs = max_mrs
        @dry_run = dry_run
        @logger = Logger.new($stdout)
        @target_branch = target_branch
        @push_when_approved = push_when_approved
        @push_when_conflict = push_when_conflict
        require_keeps

        @keeps = if keeps
                   keeps.map { |k| k.is_a?(String) ? k.constantize : k }
                 else
                   all_keeps
                 end

        @filter_identifiers = ::Gitlab::Housekeeper::FilterIdentifiers.new(filter_identifiers)
      end

      def run
        mrs_created_count = 0

        git.with_clean_state do
          @keeps.each do |keep_class|
            @logger.puts "Running keep #{keep_class}"
            keep = keep_class.new(logger: @logger, filter_identifiers: @filter_identifiers)
            keep.each_identified_change do |change|
              mrs_created_count += 1 if process_change(change, keep, keep_class)
              break if mrs_created_count >= @max_mrs
            end
            break if mrs_created_count >= @max_mrs
          end
        end

        print_completion_message(mrs_created_count)
      end

      def process_change(change, keep, keep_class)
        change.keep_class ||= keep_class
        branch_name = git.create_branch(change)
        return false unless allowed_change?(change, branch_name, keep)

        keep.make_change!(change)

        add_standard_change_data(change)

        unless change.valid?
          @logger.warn "Ignoring invalid change from #{keep_class} with identifier #{change.identifiers}"
          return false
        end

        return false if skip_change_if_aborted(change, branch_name)

        merge_request_manager.setup(change, branch_name, keep) unless @dry_run

        git.in_branch(branch_name) do
          Gitlab::Housekeeper::Substitutor.perform(change)
          git.create_commit(change)
        end

        print_change_details(change, branch_name)
        merge_request_manager.create_or_update(change, branch_name, keep) unless @dry_run

        true
      end

      def allowed_change?(change, branch_name, keep)
        unless @filter_identifiers.matches_filters?(change.identifiers)
          @logger.puts "Skipping change: #{change.identifiers} due to not matching filter."
          return false
        end

        if !@dry_run && !keep.recreate_when_closed? && merge_request_manager.closed_merge_request_exists?(branch_name)
          @logger.puts "Skipping change: #{change.identifiers} as we have closed an MR for this branch #{branch_name}"
          return false
        end

        true
      end

      def print_completion_message(mrs_created_count)
        mr_count_string = "#{mrs_created_count} #{'MR'.pluralize(mrs_created_count)}"

        completion_message = if @dry_run
                               "Dry run complete. Housekeeper would have created #{mr_count_string} on an actual run."
                             else
                               "Housekeeper created #{mr_count_string}."
                             end

        @logger.puts AmazingPrint::Colors.yellowish(completion_message)
        @logger.puts
      end

      def add_standard_change_data(change)
        change.labels ||= []
        change.labels << 'automation:gitlab-housekeeper-authored'
      end

      def skip_change_if_aborted(change, branch_name)
        return false unless change.aborted?

        git.in_branch(branch_name) do
          git.create_commit(change)
        end

        @logger.puts "Skipping change as it is marked aborted."
        @logger.puts "Modified files have been committed to branch #{AmazingPrint::Colors.yellowish(branch_name)}, " \
                     "but will not be pushed."
        @logger.puts
        true
      end

      def git
        @git ||= ::Gitlab::Housekeeper::Git.new(logger: @logger, branch_from: @target_branch)
      end

      def merge_request_manager
        @merge_request_manager ||= ::Gitlab::Housekeeper::MergeRequestManager.new(
          git: git,
          target_branch: @target_branch,
          push_when_approved: @push_when_approved,
          push_when_conflict: @push_when_conflict
        )
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

        @logger.puts AmazingPrint::Colors.yellowish(base_message)
        @logger.puts AmazingPrint::Colors.purple("=> #{change.identifiers.join(': ')}")

        @logger.puts AmazingPrint::Colors.purple('=> Title:')
        @logger.puts AmazingPrint::Colors.purple(change.title)
        @logger.puts

        @logger.puts '=> Description:'
        @logger.puts change.mr_description
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

      def all_keeps
        @all_keeps ||= ObjectSpace.each_object(Class).select { |klass| klass < Keep }
      end
    end
  end
end
