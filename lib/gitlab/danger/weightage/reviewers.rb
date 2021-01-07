# frozen_string_literal: true

require_relative '../weightage'

module Gitlab
  module Danger
    module Weightage
      # Weights after (current multiplier of 2)
      #
      # +------------------------------+--------------------------------+
      # |        reviewer type         | weight(times in reviewer pool) |
      # +------------------------------+--------------------------------+
      # | reduced capacity reviewer    |                              1 |
      # | reviewer                     |                              2 |
      # | hungry reviewer              |                              4 |
      # | reduced capacity traintainer |                              3 |
      # | traintainer                  |                              6 |
      # | hungry traintainer           |                              8 |
      # +------------------------------+--------------------------------+
      #
      class Reviewers
        DEFAULT_REVIEWER_WEIGHT = CAPACITY_MULTIPLIER * BASE_REVIEWER_WEIGHT
        TRAINTAINER_WEIGHT = 3

        def initialize(reviewers, traintainers)
          @reviewers = reviewers
          @traintainers = traintainers
        end

        def execute
          # TODO: take CODEOWNERS into account?
          # https://gitlab.com/gitlab-org/gitlab/issues/26723

          weighted_reviewers + weighted_traintainers
        end

        private

        attr_reader :reviewers, :traintainers

        def weighted_reviewers
          reviewers.each_with_object([]) do |reviewer, total_reviewers|
            add_weighted_reviewer(total_reviewers, reviewer, BASE_REVIEWER_WEIGHT)
          end
        end

        def weighted_traintainers
          traintainers.each_with_object([]) do |reviewer, total_traintainers|
            add_weighted_reviewer(total_traintainers, reviewer, TRAINTAINER_WEIGHT)
          end
        end

        def add_weighted_reviewer(reviewers, reviewer, weight)
          if reviewer.reduced_capacity
            reviewers.fill(reviewer, reviewers.size, weight)
          elsif reviewer.hungry
            reviewers.fill(reviewer, reviewers.size, weight * CAPACITY_MULTIPLIER + DEFAULT_REVIEWER_WEIGHT)
          else
            reviewers.fill(reviewer, reviewers.size, weight * CAPACITY_MULTIPLIER)
          end
        end
      end
    end
  end
end
