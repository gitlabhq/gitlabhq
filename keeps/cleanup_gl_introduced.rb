# frozen_string_literal: true

require_relative 'helpers/reviewer_roulette'
require_relative '../scripts/graphql/cleanup_gl_introduced'

module Keeps
  # Removes stale `@gl_introduced` directives from the frontend GraphQL files.
  # See scripts/graphql/cleanup_gl_introduced.rb for what counts as stale.
  #
  # The identifier does not include the milestone, so a run updates the MR that
  # is still open from an earlier milestone instead of opening a second one.
  #
  # You can run this keep with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::CleanupGlIntroduced
  # ```
  class CleanupGlIntroduced < ::Gitlab::Housekeeper::Keep
    LABELS = %w[type::maintenance maintenance::refactor frontend].freeze

    def each_identified_change
      return if cleanup(dry_run: true).execute.empty?

      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = [self.class.name.demodulize]
      yield(change)
    end

    def make_change!(change)
      cleanup_instance = cleanup(dry_run: false)
      changes = cleanup_instance.execute
      # The cleanup keeps the line layout, so a field can be left split where Prettier wants one line.
      ::Gitlab::Housekeeper::Shell.execute('yarn', 'run', 'prettier', '--write', *changes.keys)

      change.title = 'Remove stale @gl_introduced directives'
      change.description = description(changes, cleanup_instance.cutoff_milestone_name)
      change.labels = LABELS
      change.reviewers = roulette.random_reviewer_for('maintainer::frontend')
      change.changed_files = changes.keys

      change
    end

    private

    def cleanup(dry_run:)
      ::CleanupGlIntroduced.new(dry_run: dry_run, output: StringIO.new)
    end

    def description(changes, cutoff)
      files = changes.map { |path, count| "- `#{path}` (#{count})" }.join("\n")

      <<~MARKDOWN
        ## What does this MR do and why?

        Removes `@gl_introduced` directives tagged with a milestone older than #{cutoff}.

        The backend only strips a tagged node while the tagged milestone is its own
        milestone or later (`Gitlab::Graphql::VersionFilter::FutureFieldFilter#future_node?`).
        Directives from the previous milestone are kept, in case their MR missed the release.

        Removed #{changes.values.sum} directive(s) from #{changes.size} file(s):

        #{files}

        Directives outside `*.graphql` files, for example in JavaScript query strings, are not
        removed and need manual cleanup.
      MARKDOWN
    end

    def roulette
      ::Keeps::Helpers::ReviewerRoulette.instance
    end
  end
end
