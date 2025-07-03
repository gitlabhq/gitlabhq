# frozen_string_literal: true

module Ci
  module Builds
    Timeout = Struct.new(:value, :source)

    class TimeoutCalculator
      def self.timeout_sources
        Ci::BuildMetadata.timeout_sources
      end

      def initialize(build)
        @build = build
      end

      def applicable_timeout
        [job_timeout || project_timeout, runner_timeout].compact.min_by(&:value)
      end

      private

      attr_reader :build

      def job_timeout
        value = build.options[:job_timeout]
        return unless value

        Ci::Builds::Timeout.new(value, fetch_source(:job_timeout_source))
      end

      def project_timeout
        value = build.project&.build_timeout
        return unless value

        Ci::Builds::Timeout.new(value, fetch_source(:project_timeout_source))
      end

      def runner_timeout
        value = build.runner&.maximum_timeout.to_i
        return unless value > 0

        Ci::Builds::Timeout.new(value, fetch_source(:runner_timeout_source))
      end

      def fetch_source(source)
        self.class.timeout_sources.fetch(source)
      end
    end
  end
end
