# frozen_string_literal: true

module Observability
  # Shared request-parsing helpers for the group- and project-level
  # observability iframe controllers (Groups::ObservabilityController,
  # Projects::ObservabilityController).
  #
  # #show itself, the CSP block, authorize_read_observability!, and
  # bff_session_endpoint stay on each controller: they differ enough
  # (project's #show has the multi-branch setup/redirect logic; project's
  # authorization has to fall back across the project's own permissions when
  # it has no group) that folding them into the concern would trade real
  # duplication for a harder-to-follow abstraction. Only the byte-identical
  # request-parsing helpers are shared here.
  module ShowActions
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      before_action :authenticate_user!
      before_action :authorize_read_observability!
      before_action :reject_path_traversal!

      feature_category :observability
      urgency :low
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

    # Filters the incoming query string according to the allowlist and size limit
    # defined in the presenter. Returns a plain Hash of permitted key/value pairs.
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
