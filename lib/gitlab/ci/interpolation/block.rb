# frozen_string_literal: true

module Gitlab
  module Ci
    module Interpolation
      class Block
        PREFIX = '$[['
        PATTERN = /(?<block>\$\[\[\s*(?<access>.*?)\s*\]\])/.freeze

        attr_reader :block, :data, :ctx

        def initialize(block, data, ctx)
          @block = block
          @ctx = ctx
          @data = data

          @access = Interpolation::Access.new(@data, ctx)
        end

        def valid?
          errors.none?
        end

        def errors
          @access.errors
        end

        def content
          @access.content
        end

        def value
          raise ArgumentError, 'block invalid' unless valid?

          @access.value
        end

        def self.match(data)
          return data unless data.is_a?(String) && data.include?(PREFIX)

          data.gsub(PATTERN) do
            yield ::Regexp.last_match(1), ::Regexp.last_match(2)
          end
        end
      end
    end
  end
end
