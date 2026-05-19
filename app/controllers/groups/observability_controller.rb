# frozen_string_literal: true

module Groups
  class ObservabilityController < Groups::ApplicationController
    include Gitlab::Utils::StrongMemoize

    before_action :authenticate_user!
    before_action :authorize_read_observability!
    before_action :reject_path_traversal!

    feature_category :observability
    urgency :low

    content_security_policy_with_context do |p|
      o11y_url = group.observability_group_o11y_setting&.o11y_service_url
      next unless o11y_url.present?

      existing_frame_src = p.directives['frame-src']
      frame_src_values = Array.wrap(existing_frame_src) | ["'self'", o11y_url]
      p.frame_src(*frame_src_values)
    end

    def show
      path = observability_path
      return render_404 unless ::Observability::ObservabilityPresenter.valid_path?(path)

      @data = ::Observability::ObservabilityPresenter.new(group, path, query_params: filtered_query_params)

      respond_to do |format|
        format.html { render }
        format.json { render json: @data.to_h }
      end
    end

    private

    # Returns the sub-path from the request, normalising single-segment (:id)
    # and multi-segment (*sub_path) parameters to a plain string.
    def observability_path
      permitted_params[:sub_path] || permitted_params[:id].to_s
    end
    strong_memoize_attr :observability_path

    def permitted_params
      params.permit(:id, :sub_path)
    end

    def reject_path_traversal!
      Gitlab::PathTraversal.check_path_traversal!(observability_path)
    rescue Gitlab::PathTraversal::PathTraversalAttackError
      render_404
    end

    def authorize_read_observability!
      return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

      render_404 unless Ability.allowed?(current_user, :read_observability_portal, group)
    end

    # Filters the incoming query string according to the allowlist and size limit
    # defined in the presenter.  Returns a plain Hash of permitted key/value pairs.
    #
    # We use request.query_parameters (bypassing strong params) intentionally: this
    # is read-only forwarding to the iframe, not a model-mutating operation.
    def filtered_query_params
      raw_qs = request.query_string

      return {} if raw_qs.bytesize > ::Observability::ObservabilityPresenter::QUERY_STRING_MAX_BYTES

      allowed_keys = ::Observability::ObservabilityPresenter::ALLOWED_QUERY_PARAMS

      request.query_parameters
        .slice(*allowed_keys)
        .select { |_k, v| v.is_a?(String) }
    end
  end
end
