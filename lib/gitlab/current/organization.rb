# frozen_string_literal: true

module Gitlab
  module Current
    class Organization
      include Gitlab::Utils::StrongMemoize

      HTTP_HEADER = "X-GitLab-Organization-ID"

      attr_reader :params

      def initialize(params: {}, user: nil, rack_env: nil)
        @params = params
        @user_or_proc = user
        @headers = rack_env ? Rack::Proxy.extract_http_request_headers(rack_env) : nil
      end

      def organization
        from_request || from_user || fallback_organization
      end

      # The Organization a request's path/header names, if any - see
      # https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/contexts/.
      # Does not fall back to the User's home Organization or the default Organization -
      # those are not what the request is about, see #from_user and Gitlab::Current::DataContext respectively.
      def from_request
        from_params || from_headers
      end
      strong_memoize_attr :from_request

      def from_params
        from_group_params || from_organization_params
      end

      def from_headers
        return if headers.nil?

        header_organization_id = headers[HTTP_HEADER]

        return unless header_organization_id.to_i > 0

        ::Organizations::Organization.find_by_id_with_isolation_record(header_organization_id)
      end

      def from_user
        return unless user

        ::Organizations::Organization.find_by_id_with_isolation_record(user.organization_id)
      end

      def user
        return @user if defined?(@user)

        @user = @user_or_proc.respond_to?(:call) ? @user_or_proc.call : @user_or_proc
      end

      private

      attr_reader :headers

      def from_group_params
        path = params[:namespace_id] || params[:group_id]
        path ||= params[:id] if params[:controller] == 'groups'

        return if path.blank?

        ::Organizations::Organization.find_by_namespace_path_with_isolation_record(path)
      end

      def from_organization_params
        path = params[:organization_path]
        return if path.blank?

        ::Organizations::Organization.find_by_path_with_isolation_record(path)
      end

      def fallback_organization
        Gitlab::Organizations::FallbackOrganizationTracker.enable

        ::Organizations::Organization.default_organization
      end
    end
  end
end
