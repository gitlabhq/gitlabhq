# frozen_string_literal: true

require_relative 'helpers/reviewer_roulette'

module Keeps
  # Moves the date of the `baseline widely available on YYYY-MM-DD` query in
  # `.browserslistrc` to the first day of the current month.
  #
  # Using the first day of the month makes every run within a month produce the same
  # change, so a rerun does not move the date of the MR that is still open.
  #
  # You can run this keep with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::UpdateBrowserslistBaselineDate
  # ```
  class UpdateBrowserslistBaselineDate < ::Gitlab::Housekeeper::Keep
    BROWSERSLISTRC_PATH = '.browserslistrc'
    BASELINE_QUERY_REGEX = /^baseline widely available on (?<date>\d{4}-\d{2}-\d{2})$/
    LABELS = %w[type::maintenance maintenance::dependency frontend].freeze

    # Every month reuses the same branch, so closing one month's MR must not stop later ones.
    def recreate_when_closed?
      true
    end

    def each_identified_change
      pinned_date = read_pinned_date
      return if pinned_date.nil? || pinned_date >= target_date

      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = [self.class.name.demodulize]
      change.context = { from: pinned_date.iso8601, to: target_date.iso8601 }
      yield(change)
    end

    def make_change!(change)
      from = change.context[:from]
      to = change.context[:to]
      # Also updates the browsersl.ist link in the comments.
      File.write(BROWSERSLISTRC_PATH, File.read(BROWSERSLISTRC_PATH).gsub(from, to))

      change.title = "Update the Baseline date in .browserslistrc to #{to}"
      change.description = description(from, to)
      # The runner appends its own label after this method returns.
      change.labels = LABELS.dup
      # Seeding with the date keeps reruns on one reviewer and rotates reviewers monthly.
      change.reviewers = roulette.random_reviewer_for('maintainer::frontend', identifiers: change.identifiers + [to])
      change.changed_files = [BROWSERSLISTRC_PATH]

      change
    end

    private

    def read_pinned_date
      match = File.read(BROWSERSLISTRC_PATH).match(BASELINE_QUERY_REGEX)
      Date.iso8601(match[:date]) if match
    end

    def target_date
      Date.current.beginning_of_month
    end

    def description(from, to)
      <<~MARKDOWN
        ## What does this MR do and why?

        Moves the Baseline Widely available date in `.browserslistrc` from #{from} to #{to}.

        `.browserslistrc` pins the date so that the compiled assets do not depend on the day
        of the build. This keep moves it forward every month, so the targeted browsers keep
        following Baseline Widely available.

        Compare the targeted browsers:

        - Before: #{browserslist_url(from)}
        - After: #{browserslist_url(to)}
      MARKDOWN
    end

    def browserslist_url(date)
      "https://browsersl.ist/#q=baseline%20widely%20available%20on%20#{date}"
    end

    def roulette
      ::Keeps::Helpers::ReviewerRoulette.instance
    end
  end
end
