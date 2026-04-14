# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class JiraUser
      ADMIN_GROUPS = %w[site-admins org-admins].freeze

      def initialize(data)
        @data = data
      end

      def jira_admin?
        matched_admin_groups.any?
      end

      # Returns a human-readable explanation of why the admin check
      # failed, including the user's actual group memberships.
      def not_an_admin_error_message
        return if jira_admin?

        group_names = user_group_names

        if group_names.empty?
          format(
            s_('JiraConnect|User is not a member of any Jira groups. ' \
              'The user must be a member of one of the following ' \
              'groups: %{required_groups}'),
            required_groups: ADMIN_GROUPS.join(', ')
          )
        else
          format(
            s_('JiraConnect|User is not a member of the ' \
              '%{required_groups} group(s). ' \
              'Current groups: %{current_groups}'),
            required_groups: ADMIN_GROUPS.join(' or '),
            current_groups: group_names.join(', ')
          )
        end
      end

      private

      def groups
        @data.dig('groups', 'items') || []
      end

      def user_group_names
        groups.filter_map { |group| group['name'] }
      end

      def matched_admin_groups
        user_group_names.select { |name| ADMIN_GROUPS.include?(name) }
      end
    end
  end
end
