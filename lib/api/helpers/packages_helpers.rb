# frozen_string_literal: true

module API
  module Helpers
    module PackagesHelpers
      MAX_PACKAGE_FILE_SIZE = 50.megabytes.freeze

      def require_packages_enabled!
        not_found! unless ::Gitlab.config.packages.enabled
      end

      def require_dependency_proxy_enabled!
        not_found! unless ::Gitlab.config.dependency_proxy.enabled
      end

      def authorize_read_package!(subject = user_project)
        authorize!(:read_package, subject)
      end

      def authorize_create_package!(subject = user_project)
        authorize!(:create_package, subject)
      end

      def authorize_destroy_package!(subject = user_project)
        authorize!(:destroy_package, subject)
      end

      def authorize_packages_access!(subject = user_project)
        require_packages_enabled!
        authorize_read_package!(subject)
      end

      def authorize_workhorse!(subject: user_project, has_length: true, maximum_size: MAX_PACKAGE_FILE_SIZE)
        authorize_upload!(subject)

        Gitlab::Workhorse.verify_api_request!(headers)

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

        params = { has_length: has_length }
        params[:maximum_size] = maximum_size unless has_length
        ::Packages::PackageFileUploader.workhorse_authorize(**params)
      end

      def authorize_upload!(subject = user_project)
        authorize_create_package!(subject)
        require_gitlab_workhorse!
      end

      def track_package_event(event_name, scope, **args)
        ::Packages::CreateEventService.new(nil, current_user, event_name: event_name, scope: scope).execute
        category = args.delete(:category) || self.options[:for].name
        ::Gitlab::Tracking.event(category, event_name.to_s, **args)
      end
    end
  end
end
