# frozen_string_literal: true

module Keeps
  module Helpers
    class Groups
      GROUPS_JSON_URL = "https://about.gitlab.com/groups.json"
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

      def pick_reviewer(group, identifiers)
        return unless group
        return if group['backend_engineers'].empty?

        # Use the change identifiers as a stable way to pick the same reviewer. Otherwise we'd assign a new reviewer
        # every time we re-ran housekeeper.
        random_engineer = Digest::SHA256.hexdigest(identifiers.join).to_i(16) % group['backend_engineers'].size

        group['backend_engineers'][random_engineer]
      end

      def pick_reviewer_for_feature_category(category, identifiers, fallback_feature_category: nil)
        pick_reviewer(
          group_for_feature_category(category),
          identifiers
        ) || pick_reviewer(
          group_for_feature_category(fallback_feature_category),
          identifiers
        )
      end

      def labels_for_feature_category(category)
        Array(
          group_for_feature_category(category)&.dig('label')
        )
      end

      private

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
