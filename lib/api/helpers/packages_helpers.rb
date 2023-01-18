# frozen_string_literal: true

module API
  module Helpers
    module PackagesHelpers
      extend ::Gitlab::Utils::Override

      MAX_PACKAGE_FILE_SIZE = 50.megabytes.freeze
      ALLOWED_REQUIRED_PERMISSIONS = %i[read_package read_group].freeze

      def require_packages_enabled!
        not_found! unless ::Gitlab.config.packages.enabled
      end

      def require_dependency_proxy_enabled!
        not_found! unless ::Gitlab.config.dependency_proxy.enabled
      end

      def authorize_read_package!(subject = user_project)
        authorize!(:read_package, subject.try(:packages_policy_subject) || subject)
      end

      def authorize_create_package!(subject = user_project)
        authorize!(:create_package, subject)
      end

      def authorize_destroy_package!(subject = user_project)
        authorize!(:destroy_package, subject)
      end

      def authorize_packages_access!(subject = user_project, required_permission = :read_package)
        require_packages_enabled!
        return forbidden! unless required_permission.in?(ALLOWED_REQUIRED_PERMISSIONS)

        if required_permission == :read_package
          authorize_read_package!(subject)
        else
          authorize!(required_permission, subject)
        end
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

      override :user_project
      def user_project(action: :read_project)
        case action
        when :read_project
          super()
        when :read_package
          user_project_with_read_package
        else
          raise ArgumentError, "unexpected action: #{action}"
        end
      end

      # This function is similar to the `find_project!` function, but it considers the `read_package` ability.
      def user_project_with_read_package
        strong_memoize(:user_project_with_read_package) do
          project = find_project(params[:id])

          next forbidden! unless authorized_project_scope?(project)

          next project if can?(current_user, :read_package, project&.packages_policy_subject)
          # guest users can have :read_project but not :read_package
          next forbidden! if can?(current_user, :read_project, project)
          next unauthorized! if authenticate_non_public?

          not_found!('Project')
        end
      end

      def track_package_event(action, scope, **args)
        ::Packages::CreateEventService.new(nil, current_user, event_name: action, scope: scope).execute
        category = args.delete(:category) || self.options[:for].name
        event_name = "i_package_#{scope}_user"
        ::Gitlab::Tracking.event(
          category,
          action.to_s,
          property: event_name,
          label: 'redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly',
          context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event_name).to_context],
          **args
        )
      end

      def present_package_file!(package_file, supports_direct_download: true)
        package_file.package.touch_last_downloaded_at
        present_carrierwave_file!(package_file.file, supports_direct_download: supports_direct_download)
      end
    end
  end
end
