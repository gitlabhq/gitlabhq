require 'json'

module RspecFlaky
  class Listener
    # - suite_flaky_examples: contains all the currently tracked flacky example
    #   for the whole RSpec suite
    # - flaky_examples: contains the examples detected as flaky during the
    #   current RSpec run
    attr_reader :suite_flaky_examples, :flaky_examples

    def initialize(suite_flaky_examples_json = nil)
      @flaky_examples = FlakyExamplesCollection.new
      @suite_flaky_examples = init_suite_flaky_examples(suite_flaky_examples_json)
    end

    def example_passed(notification)
      current_example = RspecFlaky::Example.new(notification.example)

      return unless current_example.attempts > 1

      flaky_example = suite_flaky_examples.fetch(current_example.uid) { FlakyExample.new(current_example) }
      flaky_example.update_flakiness!(last_attempts_count: current_example.attempts)

      flaky_examples[current_example.uid] = flaky_example
    end

    def dump_summary(_)
      write_report_file(flaky_examples, RspecFlaky::Config.flaky_examples_report_path)

      new_flaky_examples = flaky_examples - suite_flaky_examples
      if new_flaky_examples.any?
        Rails.logger.warn "\nNew flaky examples detected:\n"
        Rails.logger.warn JSON.pretty_generate(new_flaky_examples.to_report)

        write_report_file(new_flaky_examples, RspecFlaky::Config.new_flaky_examples_report_path)
      end
    end

    def to_report(examples)
      Hash[examples.map { |k, ex| [k, ex.to_h] }]
    end

    private

    def init_suite_flaky_examples(suite_flaky_examples_json = nil)
      unless suite_flaky_examples_json
        return {} unless File.exist?(RspecFlaky::Config.suite_flaky_examples_report_path)

        suite_flaky_examples_json = File.read(RspecFlaky::Config.suite_flaky_examples_report_path)
      end

      FlakyExamplesCollection.from_json(suite_flaky_examples_json)
    end

    def write_report_file(examples_collection, file_path)
      return unless RspecFlaky::Config.generate_report?

      report_path_dir = File.dirname(file_path)
      FileUtils.mkdir_p(report_path_dir) unless Dir.exist?(report_path_dir)

      File.write(file_path, JSON.pretty_generate(examples_collection.to_report))
    end
  end
end
