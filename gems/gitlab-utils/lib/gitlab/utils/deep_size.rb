# frozen_string_literal: true

require 'objspace'

module Gitlab
  module Utils
    class DeepSize
      Error = Class.new(StandardError)
      TooMuchDataError = Class.new(Error)

      DEFAULT_MAX_SIZE = 1.megabyte
      DEFAULT_MAX_DEPTH = 100

      def initialize(root, max_size: DEFAULT_MAX_SIZE, max_depth: DEFAULT_MAX_DEPTH)
        @root = root
        @max_size = max_size || DEFAULT_MAX_SIZE
        @max_depth = max_depth || DEFAULT_MAX_DEPTH
        @size = 0
        @depth = 0

        evaluate
      end

      def valid?
        !too_big? && !too_deep?
      end

      private

      def evaluate
        add_object(@root)
      rescue Error
        # NOOP
      end

      def too_big?
        @size > @max_size
      end

      def too_deep?
        @depth > @max_depth
      end

      def add_object(object)
        @size += ObjectSpace.memsize_of(object)
        raise TooMuchDataError if @size > @max_size

        add_array(object) if object.is_a?(Array)
        add_hash(object) if object.is_a?(Hash)
      end

      def add_array(object)
        with_nesting do
          object.each do |n|
            add_object(n)
          end
        end
      end

      def add_hash(object)
        with_nesting do
          object.each do |key, value|
            add_object(key)
            add_object(value)
          end
        end
      end

      def with_nesting
        @depth += 1
        raise TooMuchDataError if too_deep?

        yield

        @depth -= 1
      end
    end
  end
end
