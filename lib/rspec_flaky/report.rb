require 'json'
require 'time'

require_relative 'config'
require_relative 'flaky_examples_collection'

module RspecFlaky
  # This class is responsible for loading/saving JSON reports, and pruning
  # outdated examples.
  class Report < SimpleDelegator
    OUTDATED_DAYS_THRESHOLD = 90

    attr_reader :flaky_examples

    def self.load(file_path)
      load_json(File.read(file_path))
    end

    def self.load_json(json)
      new(RspecFlaky::FlakyExamplesCollection.new(JSON.parse(json)))
    end

    def initialize(flaky_examples)
      unless flaky_examples.is_a?(RspecFlaky::FlakyExamplesCollection)
        raise ArgumentError, "`flaky_examples` must be a RspecFlaky::FlakyExamplesCollection, #{flaky_examples.class} given!"
      end

      @flaky_examples = flaky_examples
      super(flaky_examples)
    end

    def write(file_path)
      unless RspecFlaky::Config.generate_report?
        puts "! Generating reports is disabled. To enable it, please set the `FLAKY_RSPEC_GENERATE_REPORT=1` !" # rubocop:disable Rails/Output
        return
      end

      report_path_dir = File.dirname(file_path)
      FileUtils.mkdir_p(report_path_dir) unless Dir.exist?(report_path_dir)

      File.write(file_path, JSON.pretty_generate(flaky_examples.to_h))
    end

    def prune_outdated(days: OUTDATED_DAYS_THRESHOLD)
      outdated_date_threshold = Time.now - (3600 * 24 * days)
      updated_hash = flaky_examples.dup
        .delete_if do |uid, hash|
          hash[:last_flaky_at] && Time.parse(hash[:last_flaky_at]).to_i < outdated_date_threshold.to_i
        end

      self.class.new(RspecFlaky::FlakyExamplesCollection.new(updated_hash))
    end
  end
end
