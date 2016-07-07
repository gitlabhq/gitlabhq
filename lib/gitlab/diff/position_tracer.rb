# Finds the diff position in the new diff that corresponds to the same location
# specified by the provided position in the old diff.
module Gitlab
  module Diff
    class PositionTracer
      attr_accessor :repository
      attr_accessor :old_diff_refs
      attr_accessor :new_diff_refs
      attr_accessor :paths

      def initialize(repository:, old_diff_refs:, new_diff_refs:, paths: nil)
        @repository = repository
        @old_diff_refs = old_diff_refs
        @new_diff_refs = new_diff_refs
        @paths = paths
      end

      def trace(old_position)
        return unless old_diff_refs.complete? && new_diff_refs.complete?
        return unless old_position.diff_refs == old_diff_refs

        # Suppose we have an MR with source branch `feature` and target branch `master`.
        # When the MR was created, the head of `master` was commit A, and the
        # head of `feature` was commit B, resulting in the original diff A->B.
        # Since creation, `master` was updated to C.
        # Now `feature` is being updated to D, and the newly generated MR diff is C->D.
        # It is possible that C and D are direct decendants of A and B respectively,
        # but this isn't necessarily the case as rebases and merges come into play.
        #
        # Suppose we have a diff note on the original diff A->B. Now that the MR
        # is updated, we need to find out what line in C->D corresponds to the
        # line the note was originally created on, so that we can update the diff note's
        # records and continue to display it in the right place in the diffs.
        # If we cannot find this line in the new diff, this means the diff note is now
        # outdated, and we will display that fact to the user.
        #
        # In the new diff, the file the diff note was originally created on may
        # have been renamed, deleted or even created, if the file existed in A and B,
        # but was removed in C, and restored in D.
        #
        # Every diff note stores a Position object that defines a specific location,
        # identified by paths and line numbers, within a specific diff, identified
        # by start, head and base commit ids.
        #
        # For diff notes for diff A->B, the position looks like this:
        # Position
        #   base_sha - ID of commit A
        #   head_sha - ID of commit B
        #   old_path - path as of A (nil if file was newly created)
        #   new_path - path as of B (nil if file was deleted)
        #   old_line - line number as of A (nil if file was newly created)
        #   new_line - line number as of B (nil if file was deleted)
        #
        # We can easily update `base_sha` and `head_sha` to hold the IDs of commits C and D,
        # but need to find the paths and line numbers as of C and D.
        #
        # If the file was unchanged or newly created in A->B, the path as of D can be found
        # by generating diff B->D ("head to head"), finding the diff file with
        # `diff_file.old_path == position.new_path`, and taking `diff_file.new_path`.
        # The path as of C can be found by taking diff C->D, finding the diff file
        # with that same `new_path` and taking `diff_file.old_path`.
        # The line number as of D can be found by using the LineMapper on diff B->D
        # and providing the line number as of B.
        # The line number as of C can be found by using the LineMapper on diff C->D
        # and providing the line number as of D.
        #
        # If the file was deleted in A->B, the path as of C can be found
        # by generating diff A->C ("base to base"), finding the diff file with
        # `diff_file.old_path == position.old_path`, and taking `diff_file.new_path`.
        # The path as of D can be found by taking diff C->D, finding the diff file
        # with that same `old_path` and taking `diff_file.new_path`.
        # The line number as of C can be found by using the LineMapper on diff A->C
        # and providing the line number as of A.
        # The line number as of D can be found by using the LineMapper on diff C->D
        # and providing the line number as of C.

        results = nil
        results ||= trace_added_line(old_position)   if old_position.added?   || old_position.unchanged?
        results ||= trace_removed_line(old_position) if old_position.removed? || old_position.unchanged?

        return unless results

        file_diff, old_line, new_line = results

        Position.new(
          old_path: file_diff.old_path,
          new_path: file_diff.new_path,
          head_sha: new_diff_refs.head_sha,
          start_sha: new_diff_refs.start_sha,
          base_sha: new_diff_refs.base_sha,
          old_line: old_line,
          new_line: new_line
        )
      end

      private

      def trace_added_line(old_position)
        file_path = old_position.new_path

        return unless diff_head_to_head

        file_head_to_head = diff_head_to_head.find { |diff_file| diff_file.old_path == file_path }

        file_path = file_head_to_head.new_path if file_head_to_head

        new_line = LineMapper.new(file_head_to_head).old_to_new(old_position.new_line)

        return unless new_line

        file_diff = new_diffs.find { |diff_file| diff_file.new_path == file_path }
        return unless file_diff

        old_line = LineMapper.new(file_diff).new_to_old(new_line)

        [file_diff, old_line, new_line]
      end

      def trace_removed_line(old_position)
        file_path = old_position.old_path

        return unless diff_base_to_base

        file_base_to_base = diff_base_to_base.find { |diff_file| diff_file.old_path == file_path }

        file_path = file_base_to_base.old_path if file_base_to_base

        old_line = LineMapper.new(file_base_to_base).old_to_new(old_position.old_line)

        return unless old_line

        file_diff = new_diffs.find { |diff_file| diff_file.old_path == file_path }
        return unless file_diff

        new_line = LineMapper.new(file_diff).old_to_new(old_line)

        [file_diff, old_line, new_line]
      end

      def diff_base_to_base
        @diff_base_to_base ||= diff_files(old_diff_refs.base_sha || old_diff_refs.start_sha, new_diff_refs.base_sha || new_diff_refs.start_sha)
      end

      def diff_head_to_head
        @diff_head_to_head ||= diff_files(old_diff_refs.head_sha, new_diff_refs.head_sha)
      end

      def new_diffs
        @new_diffs ||= diff_files(new_diff_refs.start_sha, new_diff_refs.head_sha, use_base: true)
      end

      def diff_files(start_sha, head_sha, use_base: false)
        base_sha = self.repository.merge_base(start_sha, head_sha) || start_sha

        diffs = self.repository.raw_repository.diff(
          use_base ? base_sha : start_sha,
          head_sha,
          {},
          *paths
        )

        diffs.decorate! do |diff|
          Gitlab::Diff::File.new(diff, repository: self.repository)
        end
      end
    end
  end
end
