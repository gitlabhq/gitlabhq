# frozen_string_literal: true

require 'forwardable'
require 'digest'

module Gitlab
  module RspecFlaky
    # This is a wrapper class for RSpec::Core::Example
    class Example
      extend Forwardable

      def_delegators :execution_result, :status, :exception

      def initialize(rspec_example)
        @rspec_example = rspec_example.respond_to?(:example) ? rspec_example.example : rspec_example
      end

      def uid
        @uid ||= Digest::MD5.hexdigest("#{description}-#{file}") # rubocop:disable Fips/MD5 -- MD5 is only used to compute and ID and we need to keep using for back-compat
      end

      def example_id
        rspec_example.id
      end

      def file
        metadata[:file_path]
      end

      def line
        metadata[:line_number]
      end

      def description
        metadata[:full_description]
      end

      def attempts
        rspec_example.respond_to?(:attempts) ? rspec_example.attempts : 1
      end

      def feature_category
        metadata[:feature_category]
      end

      def to_h
        {
          example_id: example_id,
          file: file,
          line: line,
          description: description,
          last_attempts_count: attempts,
          feature_category: feature_category
        }
      end

      private

      attr_reader :rspec_example

      def metadata
        rspec_example.metadata
      end

      def execution_result
        rspec_example.execution_result
      end
    end
  end
end
