# frozen_string_literal: true

module Groups
  class ObservabilityController < Groups::ApplicationController
    include ::Observability::ShowActions
    include Gitlab::InternalEventsTracking

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
      @session_endpoint = bff_session_endpoint

      track_internal_event(
        'visit_group_observability_dashboard',
        user: current_user,
        namespace: group,
        additional_properties: { label: path }
      )

      respond_to do |format|
        format.html { render }
        format.json { render json: @data.to_h }
      end
    end

    private

    def bff_session_endpoint
      return unless ::Feature.enabled?(:observability_per_user_bff_auth, group)

      group_observability_session_path(group)
    end

    def authorize_read_observability!
      return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

      render_404 unless Ability.allowed?(current_user, :read_observability_portal, group)
    end
  end
end
