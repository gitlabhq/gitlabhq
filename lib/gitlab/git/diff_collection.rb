module Gitlab
  module Git
    class DiffCollection
      include Enumerable

      DEFAULT_LIMITS = { max_files: 100, max_lines: 5000 }.freeze

      def initialize(iterator, options = {})
        @iterator = iterator
        @max_files = options.fetch(:max_files, DEFAULT_LIMITS[:max_files])
        @max_lines = options.fetch(:max_lines, DEFAULT_LIMITS[:max_lines])
        @max_bytes = @max_files * 5.kilobytes # Average 5 KB per file
        @safe_max_files = [@max_files, DEFAULT_LIMITS[:max_files]].min
        @safe_max_lines = [@max_lines, DEFAULT_LIMITS[:max_lines]].min
        @safe_max_bytes = @safe_max_files * 5.kilobytes # Average 5 KB per file
        @enforce_limits = !!options.fetch(:limits, true)
        @expanded = !!options.fetch(:expanded, true)

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

      alias_method :to_ary, :to_a

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

          if @enforce_limits && i >= @max_files
            @overflow = true
            break
          end

          expanded = !@enforce_limits || @expanded

          diff = Gitlab::Git::Diff.new(raw, expanded: expanded)

          if !expanded && over_safe_limits?(i)
            diff.collapse!
          end

          @line_count += diff.line_count
          @byte_count += diff.diff.bytesize

          if @enforce_limits && (@line_count >= @max_lines || @byte_count >= @max_bytes)
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
