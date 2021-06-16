# frozen_string_literal: true

# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    class DiffCollection
      include Enumerable

      attr_reader :limits

      delegate :max_files, :max_lines, :max_bytes, :safe_max_files, :safe_max_lines, :safe_max_bytes, to: :limits

      def self.default_limits(project: nil)
        { max_files: ::Commit.diff_safe_max_files(project: project), max_lines: ::Commit.diff_safe_max_lines(project: project) }
      end

      def self.limits(options = {})
        limits = {}
        defaults = default_limits(project: options[:project])
        limits[:max_files] = options.fetch(:max_files, defaults[:max_files])
        limits[:max_lines] = options.fetch(:max_lines, defaults[:max_lines])
        limits[:max_bytes] = limits[:max_files] * 5.kilobytes # Average 5 KB per file

        limits[:safe_max_files] = [limits[:max_files], defaults[:max_files]].min
        limits[:safe_max_lines] = [limits[:max_lines], defaults[:max_lines]].min
        limits[:safe_max_bytes] = limits[:safe_max_files] * 5.kilobytes # Average 5 KB per file
        limits[:max_patch_bytes] = Gitlab::Git::Diff.patch_hard_limit_bytes

        OpenStruct.new(limits)
      end

      def initialize(iterator, options = {})
        @iterator = iterator
        @limits = self.class.limits(options)
        @enforce_limits = !!options.fetch(:limits, true)
        @expanded = !!options.fetch(:expanded, true)
        @offset_index = options.fetch(:offset_index, 0)

        @line_count = 0
        @byte_count = 0
        @overflow = false
        @empty = true
        @array = []
      end

      def each(&block)
        @array.each(&block)

        return if @overflow
        return if @iterator.nil?

        if @iterator.is_a?(Gitlab::GitalyClient::DiffStitcher)
          each_gitaly_patch(&block)
        else
          each_serialized_patch(&block)
        end

        @populated = true

        # Allow iterator to be garbage-collected. It cannot be reused anyway.
        @iterator = nil
      end

      def sort(&block)
        @array = @array.sort(&block)

        self
      end

      def empty?
        any? # Make sure the iterator has been exercised
        @empty
      end

      def overflow?
        populate!
        !!@overflow
      end

      def overflow_max_lines?
        !!@overflow_max_lines
      end

      def overflow_max_bytes?
        !!@overflow_max_bytes
      end

      def overflow_max_files?
        !!@overflow_max_files
      end

      def collapsed_safe_lines?
        !!@collapsed_safe_lines
      end

      def collapsed_safe_files?
        !!@collapsed_safe_files
      end

      def collapsed_safe_bytes?
        !!@collapsed_safe_bytes
      end

      def size
        @size ||= count # forces a loop using each method
      end

      def real_size
        populate!

        if @overflow
          "#{size}+"
        else
          size.to_s
        end
      end

      def line_count
        populate!

        @line_count
      end

      def decorate!
        each_with_index do |element, i|
          @array[i] = yield(element)
        end
      end

      alias_method :to_ary, :to_a

      private

      def populate!
        return if @populated

        each {} # force a loop through all diffs
        nil
      end

      def over_safe_limits?(files)
        if files >= safe_max_files
          @collapsed_safe_files = true
        elsif @line_count > safe_max_lines
          @collapsed_safe_lines = true
        elsif @byte_count >= safe_max_bytes
          @collapsed_safe_bytes = true
        end

        @collapsed_safe_files || @collapsed_safe_lines || @collapsed_safe_bytes
      end

      def expand_diff?
        # Force single-entry diff collections to always present as expanded
        #
        @iterator.size == 1 || !@enforce_limits || @expanded
      end

      def each_gitaly_patch
        i = @array.length

        @iterator.each do |raw|
          diff = Gitlab::Git::Diff.new(raw, expanded: expand_diff?)

          if raw.overflow_marker
            @overflow = true
            break
          end

          yield @array[i] = diff
          i += 1
        end
      end

      def each_serialized_patch
        i = @array.length

        @iterator.each_with_index do |raw, iterator_index|
          @empty = false

          if @enforce_limits && i >= max_files
            @overflow = true
            @overflow_max_files = true
            break
          end

          diff = Gitlab::Git::Diff.new(raw, expanded: expand_diff?)

          if !expand_diff? && over_safe_limits?(i) && diff.line_count > 0
            diff.collapse!
          end

          @line_count += diff.line_count
          @byte_count += diff.diff.bytesize

          if @enforce_limits && @line_count >= max_lines
            # This last Diff instance pushes us over the lines limit. We stop and
            # discard it.
            @overflow = true
            @overflow_max_lines = true
            break
          end

          if @enforce_limits && @byte_count >= max_bytes
            # This last Diff instance pushes us over the lines limit. We stop and
            # discard it.
            @overflow = true
            @overflow_max_bytes = true
            break
          end

          # We should not yield / memoize diffs before the offset index. Though,
          # we still consider the limit buffers for diffs before it.
          if iterator_index >= @offset_index
            yield @array[i] = diff
            i += 1
          end
        end
      end
    end
  end
end
