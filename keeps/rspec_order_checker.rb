# frozen_string_literal: true

require 'yaml'

module Keeps
  # Housekeeper keep to check RSpec order dependencies and migrate specs from
  # running in specified order to running in random order.
  #
  # This keep processes specs from rspec_order_todo.yml, runs order dependency
  # checks using the existing scripts/rspec_check_order_dependence script, and
  # moves passing specs to random order while tracking failing specs separately
  # in rspec_order_failures.yml file.
  class RspecOrderChecker < ::Gitlab::Housekeeper::Keep
    LIMIT_SPECS = 20
    TODO_YAML_PATH = 'spec/support/rspec_order_todo.yml'
    FAILURE_YAML_PATH = 'spec/support/rspec_order_failures.yml'
    CHECK_SCRIPT = 'scripts/rspec_check_order_dependence'
    RELATED_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/576789'

    def initialize(
      logger: nil,
      filter_identifiers: nil,
      limit_specs: LIMIT_SPECS
    )
      super(logger: logger, filter_identifiers: filter_identifiers)
      @limit_specs = limit_specs
    end

    def each_identified_change
      unless File.exist?(TODO_YAML_PATH)
        puts "No specs to process, aborting change"
        return
      end

      todo_entries = load_todo_entries
      return if todo_entries.empty?

      entries_to_check = todo_entries.first(limit_specs)

      logger.info "Found #{todo_entries.count} entries in TODO list, checking #{entries_to_check.count}"

      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = [self.class.name.split('::').last,
        "batch_#{Time.now.strftime('%Y%m%d')}_#{todo_entries.count}"]
      change.context = {
        entries_to_check: entries_to_check,
        total_entries: todo_entries.count
      }
      yield(change)
    end

    def make_change!(change)
      entries_to_check = change.context[:entries_to_check]
      total_entries = change.context[:total_entries]

      passing_specs = []
      failing_specs = []

      entries_to_check.each do |spec_path|
        logger.info "Checking order dependency for: #{spec_path}"

        if check_order_dependency(spec_path)
          logger.info "✓ #{spec_path} passed order dependency check"
          passing_specs << spec_path
        else
          logger.info "✗ #{spec_path} failed order dependency check"
          failing_specs << spec_path
        end
      end

      all_processed_specs = passing_specs + failing_specs

      remove_specs_from_todo(all_processed_specs)
      add_specs_to_failure_list(failing_specs) if failing_specs.any?

      changed_files = [TODO_YAML_PATH]
      changed_files << FAILURE_YAML_PATH if failing_specs.any?

      change.title = build_title(passing_specs.count, failing_specs.count, all_processed_specs.count)
      change.description = build_description(passing_specs, failing_specs, total_entries)
      change.labels = ['backend', 'type::maintenance', 'test', 'Engineering Productivity']
      change.changed_files = changed_files

      change
    end

    private

    attr_reader :limit_specs

    def load_todo_entries
      todo_data = YAML.safe_load(File.read(TODO_YAML_PATH)) || []
      # Extract spec file paths from the YAML structure
      # The format is typically: "- './spec/path/to/spec_file.rb'"
      specs = todo_data.map { |entry| entry.gsub(%r{^\./}, '') }

      # Filter out EE specs for now to avoid potential licensing/service issues
      # This can be enabled in a follow-up once GDK image supports EE properly
      specs.reject! { |spec| spec.start_with?('ee/') }

      specs.sort
    rescue StandardError => e
      logger.warn "Failed to load TODO entries: #{e.message}"
      []
    end

    def load_failure_list_with_header
      content = File.read(FAILURE_YAML_PATH)
      header_match = content.match(/\A(.*?)^---\s*$/m)
      header = header_match ? header_match[1] : ""
      failure_data = YAML.safe_load(content) || []

      [header, failure_data]
    rescue StandardError => e
      logger.warn "Failed to load rspec_order_failures.yml file: #{e.message}"
      ["", []]
    end

    def check_order_dependency(spec_path)
      ::Gitlab::Housekeeper::Shell.execute(CHECK_SCRIPT, spec_path)
      true
    rescue ::Gitlab::Housekeeper::Shell::Error => e
      logger.warn "Failed to check order dependency for #{spec_path}: #{e.message}"
      false
    end

    def remove_specs_from_todo(processed_specs)
      content = File.read(TODO_YAML_PATH)

      # Extract header (everything before ---)
      header_match = content.match(/\A(.*?)^---\s*$/m)
      header = header_match ? header_match[1] : ""

      # Safe load the YAML data
      yaml_data = YAML.safe_load(content) || []

      # Remove processed specs from the data (more efficient single operation)
      yaml_data.reject! { |entry| processed_specs.include?(entry.gsub(%r{^\./}, '')) }

      write_yaml_with_single_quotes(TODO_YAML_PATH, yaml_data, header)
    end

    def add_specs_to_failure_list(failing_specs)
      header, failure_data = load_failure_list_with_header

      # Add failing specs (with ./ prefix to match TODO format)
      failing_specs.each do |spec_path|
        entry = "./#{spec_path}"
        failure_data << entry unless failure_data.include?(entry)
      end

      write_yaml_with_single_quotes(FAILURE_YAML_PATH, failure_data.sort, header)
    end

    def write_yaml_with_single_quotes(file_path, data, header = "")
      yaml_content = data.to_yaml.gsub(/^---\n/, '').gsub(/"([^"]*)"/, "'\\1'")
      File.write(file_path, "#{header}---\n#{yaml_content}")
    end

    def build_title(passing_count, failing_count, total_count)
      title = "[RSpec random order] "

      title +=
        if passing_count > 0 && failing_count > 0
          "Processed #{total_count} specs: #{passing_count} passed, #{failing_count} failed"
        elsif passing_count > 0
          "Processed #{passing_count} specs: all passed"
        else
          "Processed #{failing_count} specs: all failed"
        end

      title
    end

    def build_description(passing_specs, failing_specs, total_entries)
      all_processed = passing_specs.count + failing_specs.count

      description = <<~MARKDOWN
        ## RSpec Order Dependency Check Results

        Processed #{all_processed} spec files from `spec/support/rspec_order_todo.yml`:

        - **#{passing_specs.count} specs passed** and can now run in random order
        - **#{failing_specs.count} specs failed** and were moved to `spec/support/rspec_order_failures.yml`

        ###  Passed specs (#{passing_specs.count}):
      MARKDOWN

      description += if passing_specs.any?
                       passing_specs.map { |spec| "- `#{spec}`" }.join("\n")
                     else
                       "_None in this batch_"
                     end

      description += "\n\n### Failed specs (#{failing_specs.count}):\n"

      description += if failing_specs.any?
                       failing_specs.map { |spec| "- `#{spec}`" }.join("\n")
                     else
                       "_None in this batch_"
                     end

      description += <<~MARKDOWN

        ### Progress Summary:

        - **Processed this batch**: #{all_processed} specs
        - **Passed (can run randomly)**: #{passing_specs.count} specs
        - **Failed (moved to failure list)**: #{failing_specs.count} specs
        - **Remaining in TODO**: #{total_entries - all_processed} specs (excluding ee specs)
        - **TODO list cleanup**: Removed #{all_processed} processed entries

        ### Debugging Failed Specs:

        For specs that failed the order dependency check:

        1. **Use the existing script**: `scripts/rspec_check_order_dependence <spec_file>`
        2. **The script automatically runs**: defined order → reverse order → random order → bisect on failure
        3. **Fix the root cause**: Remove shared state or add proper cleanup
        4. **Re-test**: Run the spec again to verify the fix

        ---

        Relates to #{RELATED_ISSUE_URL}

        > The order dependency checks were performed using `scripts/rspec_check_order_dependence` which includes comprehensive testing (defined/reverse/random order) and automatic bisect analysis on failures.
      MARKDOWN

      description
    end
  end
end
