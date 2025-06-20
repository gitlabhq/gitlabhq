# frozen_string_literal: true

module Glql
  class BaseController < GraphqlController
    before_action :check_rate_limit, only: [:execute]
    before_action :set_namespace_context, only: [:execute]

    GlqlQueryLockedError = Class.new(StandardError)

    # Overrides GraphqlController#execute to add rate limiting for GLQL queries.
    # When a query times out (raising ActiveRecord::QueryAborted), we increment the
    # Gitlab::ApplicationRateLimiter counter. If a second failure occurs within a
    # 15-minute window (configured in lib/gitlab/application_rate_limiter.rb),
    # the request is throttled. One failure is allowed, but consecutive
    # failures within the time window trigger throttling.
    def execute
      start_time = Gitlab::Metrics::System.monotonic_time

      ::Gitlab::Database::LoadBalancing::SessionMap.use_replica_if_available do
        super
      end
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

    # When `set_current_context` in app/controllers/application_controller.rb calls
    # `to_lazy_hash` on Gitlab::ApplicationContext, the meta fields (meta.project and
    # meta.root_namespace) will be populated using @group or @project variables.
    def set_namespace_context
      @project ||= Project.find_by_full_path(permitted_params[:project]) if permitted_params[:project].present?
      @group ||= Group.find_by_full_path(permitted_params[:group]) if permitted_params[:group].present?
    end

    # Overrides GraphqlController#permitted_params to permit project and group params
    def permitted_standalone_query_params
      params.permit(:query, :operationName, :remove_deprecated, :group, :project, variables: {})
    end

    def logs
      graphql_logs = super.presence || [{}]

      graphql_logs.map do |log|
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
