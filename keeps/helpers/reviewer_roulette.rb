# frozen_string_literal: true

module Keeps
  module Helpers
    class ReviewerRoulette
      STATS_JSON_URL = "https://gitlab-org.gitlab.io/gitlab-roulette/stats.json"
      GITLAB_PROJECT = 'gitlab'
      Error = Class.new(StandardError)

      def random_reviewer_for(role)
        reviewers = available_reviewers_for_role(role)
        random_reviewer = reviewers.sample
        return if random_reviewer.nil?

        random_reviewer.dig(:user, :username).delete("@")
      end

      private

      def available_reviewers_for_role(role)
        available_reviewers.select { |person| reviewer_has_matching_role?(person, role) }
      end

      def reviewer_has_matching_role?(person, role)
        person.dig(:user, :type).any? { |role_pair| role_pair[:p] == GITLAB_PROJECT && role_pair[:r] == role }
      end

      def average_type?(person)
        !!person.dig(:user, :average)
      end

      def status_available?(person)
        person.dig(:status, :available)
      end

      def gitlab_reviewer?(person)
        person.dig(:user, :type).any? { |role| role[:p] == GITLAB_PROJECT }
      end

      def available_reviewers
        @available_reviewers ||= stats[:people]
          .reject { |person| average_type?(person) }
          .select { |person| gitlab_reviewer?(person) }
          .select { |person| status_available?(person) }
      end

      def stats
        @stats ||= fetch_stats
      end

      def fetch_stats
        response = Gitlab::HTTP_V2.get(STATS_JSON_URL) # rubocop:disable Gitlab/HttpV2 -- Not running inside rails application

        unless (200..299).cover?(response.code)
          raise Error, "Failed to get roulette stats with response code: #{response.code} and body:\n#{response.body}"
        end

        JSON.parse(response.body) # rubocop:disable Gitlab/Json -- We don't rely on GitLab internal classes
            .with_indifferent_access
      end
    end
  end
end
