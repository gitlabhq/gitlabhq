# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class JiraUser
      def initialize(data)
        @data = data
      end

      def site_admin?
        groups = @data.dig('groups', 'items')
        return false unless groups

        groups.any? { |g| g['name'] == 'site-admins' }
      end
    end
  end
end
