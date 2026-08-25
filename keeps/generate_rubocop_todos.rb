# frozen_string_literal: true

require_relative 'helpers/reviewer_roulette'
require_relative 'helpers/rubocop_todo_generator'
require_relative 'helpers/rubocop_grace_period_remover'

module Keeps
  # This is an implementation of ::Gitlab::Housekeeper::Keep.
  # This regenerates the `.rubocop_todo` files to avoid reintroduced the RuboCop offenses.
  #
  # It also removes RuboCop grace periods (`Details: grace period`) that have been in place long enough.
  # See https://docs.gitlab.com/development/rubocop_development_guide/#cop-grace-period.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::GenerateRubocopTodos
  # ```
  class GenerateRubocopTodos < ::Gitlab::Housekeeper::Keep
    RUBOCOP_TODO_DIR = '.rubocop_todo'
    TITLE = "Regenerate RuboCop TODO files"
    DESCRIPTION =
      <<~MARKDOWN
        Some RuboCop offenses get auto-fixed over time. To avoid
        reintroducing them, we periodically regenerate the `.rubocop_todo`
        files.

        This may also remove [`#{Helpers::RubocopGracePeriodRemover::KEY_VALUE}`](https://docs.gitlab.com/development/rubocop_development_guide/#cop-grace-period)
        grace periods at least #{Helpers::RubocopGracePeriodRemover::MIN_AGE_DAYS}
        days old.

        When reviewing, confirm:

          1. Todo files are only added, renamed, or removed, or comments
             updated — no other changes.
          2. The **rubocop** and **haml-lint** jobs pass.

        Read more about this [automation here](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#periodically-generating-rubocop-todo-files).
        Questions? Reach out in the `#f_rubocop` Slack channel.

        ### Responsibility of Assignee

        A random ~backend reviewer - fix any merge conflicts and get this
        merged like your own MR.

        ### Responsibility of Reviewer

        These changes are simple, so we skip the initial ~backend review and
        ask a random ~backend maintainer to review and merge.
      MARKDOWN
        .freeze

    def each_identified_change
      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = change_identifiers
      yield(change)
    end

    def make_change!(change)
      todo_generator.generate
      grace_period_remover.remove_overdue

      if rubocop_todo_files_unchanged?
        @logger.puts("No changes in the '#{RUBOCOP_TODO_DIR}' directory 🎉.".blue)
        return
      end

      prepare_change(change)
    end

    private

    def todo_generator
      @todo_generator ||= Helpers::RubocopTodoGenerator.new
    end

    def grace_period_remover
      @grace_period_remover ||= Helpers::RubocopGracePeriodRemover.new
    end

    def prepare_change(change)
      change.title = TITLE
      change.description = DESCRIPTION
      change.labels = labels
      change.changed_files = [RUBOCOP_TODO_DIR]
      change.assignees = reviewer('trainee maintainer::backend') || reviewer('reviewer::backend')
      change.reviewers = reviewer('maintainer::backend')
      change
    end

    def labels
      [
        'Engineering Productivity',
        'backend',
        'maintenance::workflow'
      ]
    end

    def change_identifiers
      date = Date.current
      [self.class.name.demodulize, date.year.to_s, date.month.to_s]
    end

    def reviewer(role)
      roulette.random_reviewer_for(role)
    end

    def roulette
      Keeps::Helpers::ReviewerRoulette.instance
    end

    def rubocop_todo_files_unchanged?
      cmd = %w[git status --short]
      ::Gitlab::Housekeeper::Shell.execute(*cmd, RUBOCOP_TODO_DIR).empty?
    end
  end
end
