# frozen_string_literal: true

require_relative 'reviewer_roulette'

module Keeps
  module Helpers
    class Groups
      include Singleton

      GROUPS_JSON_URL = "https://about.gitlab.com/groups.json"
      DEFAULT_REVIEWER_TYPES = ['backend_engineers'].freeze

      Error = Class.new(StandardError)

      def group_for_feature_category(category)
        return unless category

        groups.find do |_, group|
          group['categories'].present? && group['categories'].include?(category)
        end&.last
      end

      def group_for_group_label(group_label)
        groups.find do |_, group|
          group['label'] == group_label
        end&.last
      end

      def pick_reviewer(group, identifiers, reviewer_types: DEFAULT_REVIEWER_TYPES)
        return unless group

        available_reviewers = available_reviewers_for_group(group, reviewer_types: reviewer_types)
        return if available_reviewers.empty?

        # Use the change identifiers as a stable way to pick the same reviewer. Otherwise we'd assign a new reviewer
        # every time we re-ran housekeeper.
        random_engineer = Digest::SHA256.hexdigest(identifiers.join).to_i(16) % available_reviewers.size

        available_reviewers[random_engineer]
      end

      def pick_reviewer_for_feature_category(
        category, identifiers, fallback_feature_category: nil,
        reviewer_types: DEFAULT_REVIEWER_TYPES)
        pick_reviewer(
          group_for_feature_category(category),
          identifiers, reviewer_types: reviewer_types
        ) || pick_reviewer(
          group_for_feature_category(fallback_feature_category),
          identifiers, reviewer_types: reviewer_types
        )
      end

      def labels_for_feature_category(category)
        Array(
          group_for_feature_category(category)&.dig('label')
        )
      end

      def available_reviewers_for_group(group, reviewer_types: DEFAULT_REVIEWER_TYPES)
        return [] unless group

        reviewers_for_group(group, reviewer_types).select do |username|
          roulette.reviewer_available?(username)
        end
      end

      private

      def reviewers_for_group(group, reviewer_types)
        return [] unless group

        reviewer_types.flat_map { |type| group[type] || [] }.uniq
      end

      def roulette
        Keeps::Helpers::ReviewerRoulette.instance
      end

      def groups
        @groups ||= fetch_groups
      end

      def fetch_groups
        @groups_json ||= begin
          response = Gitlab::HTTP_V2.get(GROUPS_JSON_URL) # rubocop:disable Gitlab/HttpV2 -- Not running inside rails application

          unless (200..299).cover?(response.code)
            raise Error,
              "Failed to get group information with response code: #{response.code} and body:\n#{response.body}"
          end

          JSON.parse(response.body) # rubocop:disable Gitlab/Json -- We don't rely on GitLab internal classes
        end
      end
    end
  end
end
