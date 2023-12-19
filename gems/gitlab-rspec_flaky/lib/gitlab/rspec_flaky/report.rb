# frozen_string_literal: true

require 'json'
require 'time'
require 'fileutils'

require_relative 'config'
require_relative 'flaky_examples_collection'

module Gitlab
  module RspecFlaky
    # This class is responsible for loading/saving JSON reports, and pruning
    # outdated examples.
    class Report < SimpleDelegator
      OUTDATED_DAYS_THRESHOLD = 7

      attr_reader :flaky_examples

      def self.load(file_path)
        load_json(File.read(file_path))
      end

      def self.load_json(json)
        new(FlakyExamplesCollection.new(JSON.parse(json)))
      end

      def initialize(flaky_examples)
        unless flaky_examples.is_a?(FlakyExamplesCollection)
          raise ArgumentError,
            "`flaky_examples` must be a Gitlab::RspecFlaky::FlakyExamplesCollection, #{flaky_examples.class} given!"
        end

        @flaky_examples = flaky_examples
        super(flaky_examples)
      end

      def write(file_path)
        unless Config.generate_report?
          Kernel.warn "! Generating reports is disabled. To enable it, please set the `FLAKY_RSPEC_GENERATE_REPORT=1` !"
          return
        end

        report_path_dir = File.dirname(file_path)
        FileUtils.mkdir_p(report_path_dir)

        File.write(file_path, JSON.pretty_generate(flaky_examples.to_h))
      end

      def prune_outdated(days: OUTDATED_DAYS_THRESHOLD)
        outdated_date_threshold = Time.now - (3600 * 24 * days)
        recent_flaky_examples = flaky_examples.dup
          .delete_if do |_uid, flaky_example|
            last_flaky_at = flaky_example.to_h[:last_flaky_at]
            last_flaky_at && last_flaky_at.to_i < outdated_date_threshold.to_i
          end

        self.class.new(FlakyExamplesCollection.new(recent_flaky_examples))
      end
    end
  end
end
