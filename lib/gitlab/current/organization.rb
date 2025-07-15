# frozen_string_literal: true

module Gitlab
  module Current
    class Organization
      attr_reader :params, :user, :session

      SESSION_KEY = :organization_id

      def initialize(params: {}, session: nil, user: nil)
        @params = params
        @user = user
        @session = session
      end

      def organization
        from_params || from_session || from_user || fallback_organization
      end

      private

      def from_params
        from_group_params || from_organization_params
      end

      def from_user
        return unless user

        ::Organizations::Organization.with_user(user).first
      end

      def from_session
        return unless session.respond_to?(:[]) && session[SESSION_KEY]

        ::Organizations::Organization.find_by_id(session[SESSION_KEY])
      end

      def from_group_params
        path = params[:namespace_id] || params[:group_id]
        path ||= params[:id] if params[:controller] == 'groups'

        return if path.blank?

        ::Organizations::Organization.with_namespace_path(path).first
      end

      def from_organization_params
        path = params[:organization_path]
        return if path.blank?

        ::Organizations::Organization.find_by_path(path)
      end

      def fallback_organization
        Gitlab::Organizations::FallbackOrganizationTracker.enable

        ::Organizations::Organization.default_organization
      end
    end
  end
end
