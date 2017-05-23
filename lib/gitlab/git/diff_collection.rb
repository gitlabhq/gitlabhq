module Gitlab
  module Git
    class DiffCollection
      include Enumerable

      DEFAULT_LIMITS = { max_files: 100, max_lines: 5000 }.freeze

      def initialize(iterator, options = {})
        @iterator = iterator
        @max_files = options.fetch(:max_files, DEFAULT_LIMITS[:max_files])
        @max_lines = options.fetch(:max_lines, DEFAULT_LIMITS[:max_lines])
        @max_bytes = @max_files * 5120 # Average 5 KB per file
        @safe_max_files = [@max_files, DEFAULT_LIMITS[:max_files]].min
        @safe_max_lines = [@max_lines, DEFAULT_LIMITS[:max_lines]].min
        @safe_max_bytes = @safe_max_files * 5120 # Average 5 KB per file
        @all_diffs = !!options.fetch(:all_diffs, false)
        @no_collapse = !!options.fetch(:no_collapse, true)

        @line_count = 0
        @byte_count = 0
        @overflow = false
        @empty = true
        @array = Array.new
      end

      def each(&block)
        Gitlab::GitalyClient.migrate(:commit_raw_diffs) do
          each_patch(&block)
        end
      end

      def empty?
        any? # Make sure the iterator has been exercised
        @empty
      end

      def overflow?
        populate!
        !!@overflow
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

      def decorate!
        collection = each_with_index do |element, i|
          @array[i] = yield(element)
        end
        collection
      end

      private

      def populate!
        return if @populated

        each { nil } # force a loop through all diffs
        nil
      end

      def over_safe_limits?(files)
        files >= @safe_max_files || @line_count > @safe_max_lines || @byte_count >= @safe_max_bytes
      end

      def each_patch
        i = 0
        @array.each do |diff|
          yield diff
          i += 1
        end

        return if @overflow
        return if @iterator.nil?

        @iterator.each do |raw|
          @empty = false

          if !@all_diffs && i >= @max_files
            @overflow = true
            break
          end

          collapse = !@all_diffs && !@no_collapse

          diff = Gitlab::Git::Diff.new(raw, collapse: collapse)

          if collapse && over_safe_limits?(i)
            diff.prune_collapsed_diff!
          end

          @line_count += diff.line_count
          @byte_count += diff.diff.bytesize

          if !@all_diffs && (@line_count >= @max_lines || @byte_count >= @max_bytes)
            # This last Diff instance pushes us over the lines limit. We stop and
            # discard it.
            @overflow = true
            break
          end

          yield @array[i] = diff
          i += 1
        end

        @populated = true

        # Allow iterator to be garbage-collected. It cannot be reused anyway.
        @iterator = nil
      end
    end
  end
end
