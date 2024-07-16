# frozen_string_literal: true

require_relative 'helpers/reviewer_roulette'

module Keeps
  # This is an implementation of ::Gitlab::Housekeeper::Keep.
  # This regenerates the `.rubocop_todo` files to avoid reintroduced the RuboCop offenses.
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
        Due to code changes, some RuboCop offenses get automatically fixed over time. To avoid reintroducing these
        offenses, we periodically regenerate the `.rubocop_todo` files.

        While reviewing this merge request make sure:

          1. The files are only added, renamed or removed from the todo lists or the comments are updated and there
             should be no other changes.
          2. **rubocop**, **haml-lint**, and **haml-lint** jobs pass.

        Read more about this [automation here](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#periodically-generating-rubocop-todo-files).

        If you have any questions, feel free to reach out in the `#f_rubocop` channel on Slack.

        ### Responsibility of Assignee

        We pick a random ~backend reviewer as the assignee. You should make sure to fix any merge conflicts if they
        arise and get this merge request merged like any other merge request authored by you.

        ### Responsibility of Reviewer

        Since these changes are simple we skip the initial ~backend review for efficiency and request a review from a
        random ~backend maintainer to review and merge these changes.
      MARKDOWN

    def each_change
      generate_rubocop_todos

      if rubocop_todo_files_unchanged?
        @logger.puts("No changes in the '#{RUBOCOP_TODO_DIR}' directory 🎉.".blue)
        return
      end

      yield(prepare_change)
    end

    private

    def generate_rubocop_todos
      Gitlab::Application.load_tasks
      Rake::Task["rubocop:todo:generate"].invoke
    end

    def prepare_change
      ::Gitlab::Housekeeper::Change.new.tap do |change|
        change.title = TITLE
        change.description = DESCRIPTION
        change.labels = labels
        change.identifiers = change_identifiers
        change.changed_files = [RUBOCOP_TODO_DIR]
        change.assignees = reviewer('trainee maintainer::backend') || reviewer('reviewer::backend')
        change.reviewers = reviewer('maintainer::backend')
      end
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
      @roulette ||= Keeps::Helpers::ReviewerRoulette.new
    end

    def rubocop_todo_files_unchanged?
      cmd = %w[git status --short]
      ::Gitlab::Housekeeper::Shell.execute(*cmd, RUBOCOP_TODO_DIR).empty?
    end
  end
end
