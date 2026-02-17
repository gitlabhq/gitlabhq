# frozen_string_literal: true

require_relative 'helpers/milestones'
require_relative 'helpers/reviewer_roulette'

module Keeps
  class SquashMigrations < ::Gitlab::Housekeeper::Keep
    SCHEDULED_STOPS = [2, 5, 8, 11].freeze

    def each_identified_change
      return unless should_squash?

      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = change_identifiers
      yield(change)
    end

    def make_change!(change)
      squash_branch = squash_branch_name
      run_squash_task(squash_branch)

      change.title = "Squash database migrations up to #{squash_branch}"
      change.description = build_description(squash_branch)
      change.labels = labels
      change.reviewers = reviewer('maintainer::database')
      change.changed_files = all_modified_files

      change
    end

    private

    def change_identifiers
      [self.class.name.demodulize, target_squash_stop]
    end

    def should_squash?
      SCHEDULED_STOPS.include?(current_minor)
    end

    def squash_branch_name
      "origin/#{target_squash_stop.tr('.', '-')}-stable-ee"
    end

    def target_squash_stop
      stop_index = SCHEDULED_STOPS.index(current_minor)
      squash_stop_index = stop_index - 2

      if squash_stop_index >= 0
        "#{current_major}.#{SCHEDULED_STOPS[squash_stop_index]}"
      else
        "#{current_major - 1}.#{SCHEDULED_STOPS[squash_stop_index]}"
      end
    end

    def run_squash_task(branch)
      Gitlab::Housekeeper::Shell.execute('bundle', 'exec', 'rake', "gitlab:db:squash[#{branch}]")
    end

    def build_description(branch)
      <<~MARKDOWN
        ## What does this MR do and why?

        This MR removes database migrations up to #{branch} and squashes them into `db/init_structure.sql` and
        removes associated specs and rubocop todos.

        The changes were mainly created by running `bundle exec rake gitlab:db:squash[#{branch}]`.
      MARKDOWN
    end

    def labels
      ['type::maintenance', 'database', 'database::review pending', 'maintenance::refactor', 'backend']
    end

    def all_modified_files
      Gitlab::Housekeeper::Shell.execute('git', 'diff', 'HEAD', '--name-only',
        '--diff-filter=AM').split("\n").tap do |files|
        raise "Squash did not update db/init_structure.sql" unless files.any? do |f|
          f.include?('db/init_structure.sql')
        end
      end
    end

    def current_major
      @current_major ||= current_milestone.split('.').first.to_i
    end

    def current_minor
      @current_minor ||= current_milestone.split('.').last.to_i
    end

    def current_milestone
      @current_milestone ||= milestones_helper.current_milestone
    end

    def milestones_helper
      @milestones_helper ||= ::Keeps::Helpers::Milestones.new
    end

    def reviewer(role)
      roulette.random_reviewer_for(role)
    end

    def roulette
      Keeps::Helpers::ReviewerRoulette.instance
    end
  end
end
