require 'json'

module RspecFlaky
  class Listener
    # - suite_flaky_examples: contains all the currently tracked flacky example
    #   for the whole RSpec suite
    # - flaky_examples: contains the examples detected as flaky during the
    #   current RSpec run
    attr_reader :suite_flaky_examples, :flaky_examples

    def initialize(suite_flaky_examples_json = nil)
      @flaky_examples = {}
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
      write_report_file(flaky_examples, flaky_examples_report_path)

      new_flaky_examples = _new_flaky_examples
      if new_flaky_examples.any?
        Rails.logger.warn "\nNew flaky examples detected:\n"
        Rails.logger.warn JSON.pretty_generate(to_report(new_flaky_examples))

        write_report_file(new_flaky_examples, new_flaky_examples_report_path)
      end
    end

    def to_report(examples)
      Hash[examples.map { |k, ex| [k, ex.to_h] }]
    end

    private

    def init_suite_flaky_examples(suite_flaky_examples_json = nil)
      unless suite_flaky_examples_json
        return {} unless File.exist?(suite_flaky_examples_report_path)

        suite_flaky_examples_json = File.read(suite_flaky_examples_report_path)
      end

      suite_flaky_examples = JSON.parse(suite_flaky_examples_json)

      Hash[(suite_flaky_examples || {}).map { |k, ex| [k, FlakyExample.new(ex)] }].freeze
    end

    def _new_flaky_examples
      flaky_examples.reject { |uid, _| already_flaky?(uid) }
    end

    def already_flaky?(example_uid)
      suite_flaky_examples.key?(example_uid)
    end

    def write_report_file(examples, file_path)
      return unless ENV['FLAKY_RSPEC_GENERATE_REPORT'] == 'true'

      report_path_dir = File.dirname(file_path)
      FileUtils.mkdir_p(report_path_dir) unless Dir.exist?(report_path_dir)
      File.write(file_path, JSON.pretty_generate(to_report(examples)))
    end

    def suite_flaky_examples_report_path
      @suite_flaky_examples_report_path ||= ENV['SUITE_FLAKY_RSPEC_REPORT_PATH'] ||
        Rails.root.join("rspec_flaky/suite-report.json")
    end

    def flaky_examples_report_path
      @flaky_examples_report_path ||= ENV['FLAKY_RSPEC_REPORT_PATH'] ||
        Rails.root.join("rspec_flaky/report.json")
    end

    def new_flaky_examples_report_path
      @new_flaky_examples_report_path ||= ENV['NEW_FLAKY_RSPEC_REPORT_PATH'] ||
        Rails.root.join("rspec_flaky/new-report.json")
    end
  end
end
