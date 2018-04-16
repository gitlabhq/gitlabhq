require 'json'

require_relative 'config'
require_relative 'example'
require_relative 'flaky_example'
require_relative 'flaky_examples_collection'
require_relative 'report'

module RspecFlaky
  class Listener
    # - suite_flaky_examples: contains all the currently tracked flacky example
    #   for the whole RSpec suite
    # - flaky_examples: contains the examples detected as flaky during the
    #   current RSpec run
    attr_reader :suite_flaky_examples, :flaky_examples

    def initialize(suite_flaky_examples_json = nil)
      @flaky_examples = RspecFlaky::FlakyExamplesCollection.new
      @suite_flaky_examples = init_suite_flaky_examples(suite_flaky_examples_json)
    end

    def example_passed(notification)
      current_example = RspecFlaky::Example.new(notification.example)

      return unless current_example.attempts > 1

      flaky_example = suite_flaky_examples.fetch(current_example.uid) { RspecFlaky::FlakyExample.new(current_example) }
      flaky_example.update_flakiness!(last_attempts_count: current_example.attempts)

      flaky_examples[current_example.uid] = flaky_example
    end

    def dump_summary(_)
      RspecFlaky::Report.new(flaky_examples).write(RspecFlaky::Config.flaky_examples_report_path)
      # write_report_file(flaky_examples, RspecFlaky::Config.flaky_examples_report_path)

      new_flaky_examples = flaky_examples - suite_flaky_examples
      if new_flaky_examples.any?
        Rails.logger.warn "\nNew flaky examples detected:\n"
        Rails.logger.warn JSON.pretty_generate(new_flaky_examples.to_h)

        RspecFlaky::Report.new(new_flaky_examples).write(RspecFlaky::Config.new_flaky_examples_report_path)
        # write_report_file(new_flaky_examples, RspecFlaky::Config.new_flaky_examples_report_path)
      end
    end

    private

    def init_suite_flaky_examples(suite_flaky_examples_json = nil)
      if suite_flaky_examples_json
        RspecFlaky::Report.load_json(suite_flaky_examples_json).flaky_examples
      else
        return {} unless File.exist?(RspecFlaky::Config.suite_flaky_examples_report_path)

        RspecFlaky::Report.load(RspecFlaky::Config.suite_flaky_examples_report_path).flaky_examples
      end
    end
  end
end
