require 'json'

module RspecFlaky
  class Listener
    attr_reader :all_flaky_examples, :new_flaky_examples

    def initialize
      @new_flaky_examples = {}
      @all_flaky_examples = init_all_flaky_examples
    end

    def example_passed(notification)
      current_example = RspecFlaky::Example.new(notification.example)

      return unless current_example.attempts > 1

      flaky_example_hash = all_flaky_examples[current_example.uid]

      all_flaky_examples[current_example.uid] =
        if flaky_example_hash
          FlakyExample.new(flaky_example_hash).tap do |ex|
            ex.last_attempts_count = current_example.attempts
            ex.flaky_reports += 1
          end
        else
          FlakyExample.new(current_example).tap do |ex|
            new_flaky_examples[current_example.uid] = ex
          end
        end
    end

    def dump_summary(_)
      write_report_file(all_flaky_examples, all_flaky_examples_report_path)

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

    def init_all_flaky_examples
      return {} unless File.exist?(all_flaky_examples_report_path)

      all_flaky_examples = JSON.parse(File.read(all_flaky_examples_report_path))

      Hash[(all_flaky_examples || {}).map { |k, ex| [k, FlakyExample.new(ex)] }]
    end

    def write_report_file(examples, file_path)
      return unless ENV['FLAKY_RSPEC_GENERATE_REPORT'] == 'true'

      report_path_dir = File.dirname(file_path)
      FileUtils.mkdir_p(report_path_dir) unless Dir.exist?(report_path_dir)
      File.write(file_path, JSON.pretty_generate(to_report(examples)))
    end

    def all_flaky_examples_report_path
      @all_flaky_examples_report_path ||= ENV['ALL_FLAKY_RSPEC_REPORT_PATH'] ||
        Rails.root.join("rspec_flaky/all-report.json")
    end

    def new_flaky_examples_report_path
      @new_flaky_examples_report_path ||= ENV['NEW_FLAKY_RSPEC_REPORT_PATH'] ||
        Rails.root.join("rspec_flaky/new-report.json")
    end
  end
end
