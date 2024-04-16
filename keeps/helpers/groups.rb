# frozen_string_literal: true

module Keeps
  module Helpers
    class Groups
      GROUPS_JSON_URL = "https://about.gitlab.com/groups.json"
      Error = Class.new(StandardError)

      def group_for_feature_category(category)
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
        return if group['backend_engineers'].empty?

        random_engineer = Digest::SHA256.hexdigest(identifiers.join).to_i(16) % group['backend_engineers'].size

        group['backend_engineers'][random_engineer]
      end

      private

      def groups
        @groups ||= fetch_groups
      end

      def fetch_groups
        @groups_json ||= begin
          response = Gitlab::HTTP.get(GROUPS_JSON_URL)

          unless (200..299).cover?(response.code)
            raise Error,
              "Failed to get group information with response code: #{response.code} and body:\n#{response.body}"
          end

          Gitlab::Json.parse(response.body)
        end
      end
    end
  end
end
