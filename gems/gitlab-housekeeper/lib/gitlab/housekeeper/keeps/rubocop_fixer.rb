# frozen_string_literal: true

require 'yaml'

module Gitlab
  module Housekeeper
    module Keeps
      class RubocopFixer < Keep
        LIMIT_FIXES = 20
        RUBOCOP_TODO_DIR_PATTERN = ".rubocop_todo/**/*.yml"

        def initialize(logger: nil, todo_dir_pattern: RUBOCOP_TODO_DIR_PATTERN, limit_fixes: LIMIT_FIXES)
          super(logger: logger)
          @todo_dir_pattern = todo_dir_pattern
          @limit_fixes = limit_fixes
        end

        def each_change
          each_allowed_rubocop_rule do |rule, rule_file_path, violating_files|
            @logger.puts "RubopCop rule #{rule}"
            remove_allow_rule = true

            if violating_files.count > @limit_fixes
              violating_files = violating_files.first(@limit_fixes)
              remove_allow_rule = false
            end

            change = Change.new
            change.title = "Fix #{violating_files.count} rubocop violations for #{rule}"
            change.identifiers = [self.class.name, rule, violating_files.last]
            change.description = <<~MARKDOWN
            Fixes the #{violating_files.count} violations for the rubocop rule `#{rule}`
            that were previously excluded in `#{rule_file_path}`.
            The exclusions have now been removed.
            MARKDOWN

            if remove_allow_rule
              FileUtils.rm(rule_file_path)
            else
              remove_first_exclusions(rule, rule_file_path, violating_files.count)
            end

            unless Gitlab::Housekeeper::Shell.rubocop_autocorrect(violating_files)
              @logger.warn "Failed to autocorrect files. Reverting"
              # Ignore when it cannot be automatically fixed. But we need to checkout any files we might have updated.
              ::Gitlab::Housekeeper::Shell.execute('git', 'checkout', rule_file_path, *violating_files)
              next
            end

            change.changed_files = [rule_file_path, *violating_files]

            yield(change)
          end
        end

        def each_allowed_rubocop_rule
          Dir.glob(@todo_dir_pattern).each do |file|
            content = File.read(file)
            next unless content.include?('Cop supports --autocorrect')

            data = YAML.safe_load(content)

            # Assume one per file since that's how it is in gitlab-org/gitlab
            next unless data.keys.count == 1

            rule = data.keys[0]
            violating_files = data[rule]['Exclude']
            next unless violating_files&.count&.positive?

            yield rule, file, violating_files
          end
        end

        def remove_first_exclusions(_rule, file, remove_count)
          content = File.read(file)
          skipped = 0

          output = content.each_line.filter do |line|
            if skipped < remove_count && line.match?(/\s+-\s+/)
              skipped += 1
              false
            else
              true
            end
          end

          File.write(file, output.join)
        end
      end
    end
  end
end
