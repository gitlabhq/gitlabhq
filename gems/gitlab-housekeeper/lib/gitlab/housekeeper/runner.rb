# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/string'
require 'gitlab/housekeeper/logger'
require 'gitlab/housekeeper/keep_loader'
require 'gitlab/housekeeper/git'
require 'gitlab/housekeeper/change'
require 'gitlab/housekeeper/merge_request_manager'
require 'gitlab/housekeeper/printer'
require 'gitlab/housekeeper/substitutor'
require 'gitlab/housekeeper/filter_identifiers'

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
        @keeps = KeepLoader.new(requested: keeps).keeps
        @filter_identifiers = ::Gitlab::Housekeeper::FilterIdentifiers.new(filter_identifiers)
      end

      def run
        mrs_created_count = 0

        git.with_clean_state do
          keeps.each do |keep_class|
            printer.running_keep(keep_class)
            keep = keep_class.new(logger: logger, filter_identifiers: filter_identifiers)
            keep.each_identified_change do |change|
              mrs_created_count += 1 if process_change(change, keep, keep_class)
              break if mrs_created_count >= max_mrs
            end
            break if mrs_created_count >= max_mrs
          end
        end

        printer.completion(mrs_created_count)
      end

      private

      attr_reader :max_mrs, :dry_run, :logger, :target_branch, :push_when_approved, :push_when_conflict, :keeps,
        :filter_identifiers

      def process_change(change, keep, keep_class)
        change.keep_class ||= keep_class
        branch_name = git.create_branch(change)
        return false unless allowed_change?(change, branch_name, keep)

        keep.make_change!(change)

        change.add_standard_data!

        unless change.valid?
          printer.invalid_change(keep_class, change.identifiers)
          return false
        end

        return false if skip_change_if_aborted(change, branch_name)

        merge_request_manager.setup(change, branch_name, keep) unless dry_run

        git.in_branch(branch_name) do
          Gitlab::Housekeeper::Substitutor.perform(change)
          git.create_commit(change)
        end

        diff = git.diff(branch_name, change.changed_files)
        printer.change_details(change, branch_name, diff)
        merge_request_manager.create_or_update(change, branch_name, keep) unless dry_run

        true
      end

      def allowed_change?(change, branch_name, keep)
        unless filter_identifiers.matches_filters?(change.identifiers)
          printer.skipped_by_filter(change.identifiers)
          return false
        end

        if !dry_run && !keep.recreate_when_closed? && merge_request_manager.closed_merge_request_exists?(branch_name)
          printer.skipped_closed_merge_request(change.identifiers, branch_name)
          return false
        end

        true
      end

      def skip_change_if_aborted(change, branch_name)
        return false unless change.aborted?

        git.in_branch(branch_name) do
          git.create_commit(change)
        end

        printer.aborted(branch_name)
        true
      end

      def git
        @git ||= ::Gitlab::Housekeeper::Git.new(logger: logger, branch_from: target_branch)
      end

      def printer
        @printer ||= ::Gitlab::Housekeeper::Printer.new(logger: logger, dry_run: dry_run)
      end

      def merge_request_manager
        @merge_request_manager ||= ::Gitlab::Housekeeper::MergeRequestManager.new(
          git: git,
          target_branch: target_branch,
          push_when_approved: push_when_approved,
          push_when_conflict: push_when_conflict
        )
      end
    end
  end
end
