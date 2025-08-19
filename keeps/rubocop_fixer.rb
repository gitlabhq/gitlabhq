# frozen_string_literal: true

require 'yaml'

require_relative 'helpers/rubocop_fixer/file_helper'
require_relative 'helpers/rubocop_fixer/config_helper'

module Keeps
  class RubocopFixer < ::Gitlab::Housekeeper::Keep
    LIMIT_FIXES = 20
    RUBOCOP_TODO_DIR_PATTERN = ".rubocop_todo/**/*.yml"

    def initialize(
      logger: nil,
      filter_identifiers: nil,
      limit_fixes: LIMIT_FIXES
    )
      super(logger: logger, filter_identifiers: filter_identifiers)
      @limit_fixes = limit_fixes
      @config_helper = ::Keeps::Helpers::RubocopFixer::ConfigHelper.new
      @file_helper = ::Keeps::Helpers::RubocopFixer::FileHelper.new
    end

    def each_identified_change
      each_allowed_rubocop_rule do |rule, rule_file_path, violating_files|
        logger.puts "RubopCop rule #{rule}"

        limited_violating_files = if violating_files.count > limit_fixes
                                    violating_files.first(limit_fixes)
                                  else
                                    violating_files
                                  end

        remove_allow_rule = violating_files.count <= limit_fixes

        change = ::Gitlab::Housekeeper::Change.new
        change.identifiers = [self.class.name, rule]
        change.context = {
          rule: rule,
          rule_file_path: rule_file_path,
          violating_files: limited_violating_files,
          remove_allow_rule: remove_allow_rule
        }
        yield(change)
      end
    end

    def make_change!(change)
      rule = change.context[:rule]
      rule_file_path = change.context[:rule_file_path]
      violating_files = change.context[:violating_files]
      remove_allow_rule = change.context[:remove_allow_rule]

      change.title = "Fix #{violating_files.count} rubocop violations for #{rule}"
      change.labels = %w[backend type::maintenance maintenance::refactor]
      change.description = <<~MARKDOWN
        Fixes the #{violating_files.count} violations for the rubocop rule `#{rule}`
        that were previously excluded in `#{rule_file_path}`.
        The exclusions have now been removed.
      MARKDOWN

      if remove_allow_rule
        FileUtils.rm(rule_file_path)
      else
        file_helper.remove_first_exclusions(rule_file_path, violating_files.count)
      end

      unless Gitlab::Housekeeper::Shell.rubocop_autocorrect(violating_files, logger: logger)
        logger.warn "Failed to autocorrect files. Reverting"
        # Ignore when it cannot be automatically fixed. But we need to checkout any files we might have updated.
        ::Gitlab::Housekeeper::Shell.execute('git', 'checkout', rule_file_path, *violating_files)
        return
      end

      change.changed_files = [rule_file_path, *violating_files]
      change
    end

    private

    attr_reader :config_helper, :file_helper, :limit_fixes

    def each_allowed_rubocop_rule
      Dir.glob(RUBOCOP_TODO_DIR_PATTERN).each do |file|
        content = File.read(file)
        next unless content.include?('Cop supports --autocorrect')

        data = YAML.safe_load(content)

        # Assume one per file since that's how it is in gitlab-org/gitlab
        next unless data.keys.count == 1

        rule = data.keys[0]
        next unless config_helper.can_autocorrect?(rule)

        violating_files = data[rule]['Exclude']
        next unless violating_files&.count&.positive?

        yield rule, file, violating_files
      end
    end
  end
end
