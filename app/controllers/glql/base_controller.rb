# frozen_string_literal: true

module Glql
  class BaseController < GraphqlController
    before_action :check_rate_limit, only: [:execute]

    GlqlQueryLockedError = Class.new(StandardError)

    # Overrides GraphqlController#execute to add rate limiting for GLQL queries.
    # When a query times out (raising ActiveRecord::QueryAborted), we increment the
    # Gitlab::ApplicationRateLimiter counter. If a second failure occurs within a
    # 15-minute window (configured in lib/gitlab/application_rate_limiter.rb),
    # the request is throttled. One failure is allowed, but consecutive
    # failures within the time window trigger throttling.
    def execute
      start_time = Gitlab::Metrics::System.monotonic_time
      super
    rescue StandardError => error
      # We catch all errors here so they are tracked by SLIs.
      # But we only increment the rate limiter failure count for ActiveRecord::QueryAborted.
      increment_rate_limit_counter if error.is_a?(ActiveRecord::QueryAborted)

      raise error
    ensure
      increment_glql_sli(
        duration_s: Gitlab::Metrics::System.monotonic_time - start_time,
        error_type: error_type_from(error)
      )
    end

    rescue_from GlqlQueryLockedError do |exception|
      log_exception(exception)

      render_error(exception.message, status: :forbidden)
    end

    private

    def logs
      super.map do |log|
        log.merge(
          glql_referer: request.headers["Referer"],
          glql_query_sha: query_sha
        )
      end
    end

    def check_rate_limit
      return unless Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)

      raise GlqlQueryLockedError, 'Query execution is locked due to repeated failures.'
    end

    def increment_rate_limit_counter
      Gitlab::ApplicationRateLimiter.throttled?(:glql, scope: query_sha)
    end

    def query_sha
      @query_sha ||= Digest::SHA256.hexdigest(permitted_params[:query].to_s)
    end

    def increment_glql_sli(duration_s:, error_type:)
      query_urgency = Gitlab::EndpointAttributes::Config::REQUEST_URGENCIES.fetch(:low)

      labels = {
        endpoint_id: ::Gitlab::ApplicationContext.current_context_attribute(:caller_id),
        feature_category: ::Gitlab::ApplicationContext.current_context_attribute(:feature_category),
        query_urgency: query_urgency.name
      }

      Gitlab::Metrics::GlqlSlis.record_error(
        labels: labels.merge(error_type: error_type),
        error: error_type.present?
      )

      return if error_type

      Gitlab::Metrics::GlqlSlis.record_apdex(
        labels: labels.merge(error_type: nil),
        success: duration_s <= query_urgency.duration
      )
    end

    def error_type_from(exception)
      return unless exception

      case exception
      when ActiveRecord::QueryAborted
        :query_aborted
      else
        :other
      end
    end
  end
end
