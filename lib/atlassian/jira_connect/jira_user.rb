# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class JiraUser
      ADMIN_GROUPS = %w[site-admins org-admins].freeze

      def initialize(data)
        @data = data
      end

      def jira_admin?
        groups = @data.dig('groups', 'items')
        return false unless groups

        groups.any? { |group| ADMIN_GROUPS.include?(group['name']) }
      end
    end
  end
end
