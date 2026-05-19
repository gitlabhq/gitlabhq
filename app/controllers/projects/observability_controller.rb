# frozen_string_literal: true

module Projects
  class ObservabilityController < Projects::ApplicationController
    include Gitlab::Utils::StrongMemoize

    before_action :authenticate_user!
    before_action :authorize_read_observability!
    before_action :reject_path_traversal!

    feature_category :observability
    urgency :low

    content_security_policy_with_context do |p|
      o11y_url = observability_setting&.o11y_service_url
      next unless o11y_url.present?

      existing_frame_src = p.directives['frame-src']
      frame_src_values = Array.wrap(existing_frame_src) | ["'self'", o11y_url]
      p.frame_src(*frame_src_values)
    end

    def show
      path = observability_path
      return render_404 unless ::Observability::ObservabilityPresenter.valid_path?(path)

      if observability_setting
        setting_group = observability_setting.group

        @data = ::Observability::ObservabilityPresenter.new(setting_group, path, query_params: filtered_query_params)

        respond_to do |format|
          format.html { render }
          format.json { render json: @data.to_h }
        end
      else
        ancestor_group = highest_accessible_ancestor_group
        return render_404 unless ancestor_group

        redirect_to group_observability_setup_path(ancestor_group)
      end
    end

    private

    def observability_setting
      ::Observability::GroupO11ySetting.observability_setting_for(project)
    end
    strong_memoize_attr :observability_setting

    def highest_accessible_ancestor_group
      return unless project.group

      ancestors = project.group.self_and_ancestors.to_a
      access_map = current_user.max_member_access_for_group_ids(ancestors.map(&:id))

      ancestors.reverse.find { |g| access_map[g.id].to_i >= Gitlab::Access::DEVELOPER }
    end

    def authorize_read_observability!
      return render_404 unless project.group

      group = observability_setting&.group || project.group
      return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

      render_404 unless Ability.allowed?(current_user, :read_observability_portal, group)
    end

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
