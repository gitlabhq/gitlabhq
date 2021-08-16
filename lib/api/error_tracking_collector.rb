# frozen_string_literal: true

module API
  # This API is responsible for collecting error tracking information
  # from sentry client. It allows us to use GitLab as an alternative to
  # sentry backend. For more details see https://gitlab.com/gitlab-org/gitlab/-/issues/329596.
  class ErrorTrackingCollector < ::API::Base
    feature_category :error_tracking

    content_type :envelope, 'application/x-sentry-envelope'
    default_format :envelope

    before do
      not_found!('Project') unless project
      not_found! unless feature_enabled?
      not_found! unless active_client_key?
    end

    helpers do
      def project
        @project ||= find_project(params[:id])
      end

      def feature_enabled?
        project.error_tracking_setting&.enabled? &&
          project.error_tracking_setting&.integrated_client?
      end

      def find_client_key(public_key)
        return unless public_key.present?

        project.error_tracking_client_keys.active.find_by_public_key(public_key)
      end

      def active_client_key?
        begin
          public_key = ::ErrorTracking::Collector::SentryAuthParser.parse(request)[:public_key]
        rescue StandardError
          bad_request!('Failed to parse sentry request')
        end

        find_client_key(public_key)
      end
    end

    desc 'Submit error tracking event to the project' do
      detail 'This feature was introduced in GitLab 14.1.'
    end
    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    post 'error_tracking/collector/api/:id/envelope' do
      # There is a reason why we have such uncommon path.
      # We depend on a client side error tracking software which
      # modifies URL for its own reasons.
      #
      # When we give user a URL like this
      #   HOST/api/v4/error_tracking/collector/123
      #
      # Then error tracking software will convert it like this:
      #   HOST/api/v4/error_tracking/collector/api/123/envelope/

      begin
        parsed_request = ::ErrorTracking::Collector::SentryRequestParser.parse(request)
      rescue StandardError
        bad_request!('Failed to parse sentry request')
      end

      type = parsed_request[:request_type]

      # Sentry sends 2 requests on each exception: transaction and event.
      # Everything else is not a desired behavior.
      unless type == 'transaction' || type == 'event'
        render_api_error!('400 Bad Request', 400)

        break
      end

      # We don't have use for transaction request yet,
      # so we record only event one.
      if type == 'event'
        ::ErrorTracking::CollectErrorService
          .new(project, nil, event: parsed_request[:event])
          .execute
      end

      # Collector should never return any information back.
      # Because DSN and public key are designed for public use,
      # it is safe only for submission of new events.
      no_content!
    end
  end
end
