# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Access
          attr_reader :content, :errors

          MAX_ACCESS_OBJECTS = 5
          MAX_ACCESS_BYTESIZE = 1024
          MAX_ACCESS_ARRAY_DEPTH = 5
          ARRAY_INDEX_PATTERN = /\[(\d+)\]/
          ANY_BRACKET_CONTENT_PATTERN = /\[([^\]]*)\]/
          VALID_INDEXED_SEGMENT_PATTERN = /\A(\w*)(\[\d+\])+\z/

          def initialize(access, ctx)
            @content = access
            @ctx = ctx
            @errors = []

            if objects.count <= 1
              @errors.push('invalid pattern used for interpolation. valid pattern is $[[ inputs.input ]]')
            end

            if access.bytesize > MAX_ACCESS_BYTESIZE # rubocop:disable Style/IfUnlessModifier
              @errors.push('maximum interpolation expression size exceeded')
            end

            evaluate! if valid?
          end

          def valid?
            errors.none?
          end

          def objects
            @objects ||= @content.split('.', MAX_ACCESS_OBJECTS)
          end

          def value
            raise ArgumentError, 'access path invalid' unless valid?

            @value
          end

          private

          def evaluate!
            raise ArgumentError, 'access path invalid' unless valid?

            @value ||= objects.inject(@ctx) do |memo, segment|
              break if @errors.any?

              if segment.include?('[')
                evaluate_indexed_segment(memo, segment)
              else
                evaluate_key_segment(memo, segment)
              end
            end
          end

          def evaluate_key_segment(memo, segment)
            key = segment.to_sym

            unless memo.respond_to?(:key?) && memo.key?(key)
              @errors.push("unknown interpolation provided: `#{key}` in `#{@content}`")
              return
            end

            memo.fetch(key)
          end

          def evaluate_indexed_segment(memo, segment)
            parsed = parse_indexed_segment(segment)

            if parsed[:error]
              @errors.push(parsed[:error])
              return
            end

            current = evaluate_key_segment(memo, parsed[:base_key].to_s)
            return if @errors.any?

            parsed[:indices].each do |index|
              unless current.is_a?(Array)
                @errors.push("cannot index into non-array value at [#{index}] in `#{@content}`")
                return nil
              end

              if index >= current.size
                @errors.push("array index #{index} out of bounds (size: #{current.size}) in `#{@content}`")
                return nil
              end

              current = current[index]
            end

            current
          end

          def parse_indexed_segment(segment)
            match = segment.match(VALID_INDEXED_SEGMENT_PATTERN)

            if match
              return { error: "invalid indexed access without a key in `#{@content}`" } if match[1].empty?

              base_key = match[1].to_sym
              indices = segment.scan(ARRAY_INDEX_PATTERN).flatten.map(&:to_i)

              if indices.size > MAX_ACCESS_ARRAY_DEPTH
                return { error: "too many array indices in `#{@content}` " \
                           "(maximum depth: #{MAX_ACCESS_ARRAY_DEPTH})" }
              end

              return { base_key: base_key, indices: indices, error: nil }
            end

            open_count = segment.count('[')
            close_count = segment.count(']')

            if open_count != close_count
              return { error: "invalid array index in `#{@content}`: missing closing bracket" }
            end

            bracket_contents = segment.scan(ANY_BRACKET_CONTENT_PATTERN).flatten
            invalid_content = bracket_contents.find { |content| !content.match?(/^\d+$/) }

            if invalid_content
              return { error: "invalid array index in `#{@content}`: `#{invalid_content}` is not a valid index" }
            end

            { error: "invalid array index syntax in `#{@content}`" }
          end
        end
      end
    end
  end
end
