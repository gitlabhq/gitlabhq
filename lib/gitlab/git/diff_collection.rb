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
        @array = Array.new
      end

      def each(&block)
        if @populated
          # @iterator.each is slower than just iterating the array in place
          @array.each(&block)
        else
          Gitlab::GitalyClient.migrate(:commit_raw_diffs) do
            each_patch(&block)
          end
        end
      end

      def empty?
        !@iterator.any?
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
        @populated = true
        collection
      end

      private

      def populate!
        return if @populated

        each { nil } # force a loop through all diffs
        @populated = true
        nil
      end

      def over_safe_limits?(files)
        files >= @safe_max_files || @line_count > @safe_max_lines || @byte_count >= @safe_max_bytes
      end

      def each_patch
        @iterator.each_with_index do |raw, i|
          # First yield cached Diff instances from @array
          if @array[i]
            yield @array[i]
            next
          end

          # We have exhausted @array, time to create new Diff instances or stop.
          break if @overflow

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
        end
      end
    end
  end
end
