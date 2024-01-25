# frozen_string_literal: true

module Keeps
  module Helpers
    class Groups
      Error = Class.new(StandardError)

      def group_for_feature_category(category)
        @groups ||= {}
        @groups[category] ||= fetch_groups.find do |_, group|
          group['categories'].present? && group['categories'].include?(category)
        end&.last
      end

      def pick_reviewer(group, identifiers)
        random_engineer = Digest::SHA256.hexdigest(identifiers.join).to_i(16) % group['backend_engineers'].size

        group['backend_engineers'][random_engineer]
      end

      private

      def fetch_groups
        @groups_json ||= begin
          response = Gitlab::HTTP.get('https://about.gitlab.com/groups.json')

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
