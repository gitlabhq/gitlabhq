# frozen_string_literal: true

module Integrations
  module SlackInstallation
    class GroupService < BaseService
      def initialize(group, current_user:, params:)
        @group = group

        super(current_user: current_user, params: params)
      end

      private

      attr_reader :group

      def redirect_uri
        slack_auth_group_settings_slack_url(group)
      end

      def installation_alias
        group.full_path
      end

      # Returns a fallback alias for the group when the default alias (full_path) is already taken.
      def fallback_alias
        "#{group.full_path}/g-#{group.id}"
      end

      def authorized?
        current_user.can?(:admin_group, group)
      end

      def find_or_create_integration!
        GitlabSlackApplication.for_group(group).first_or_create!
      end
    end
  end
end
