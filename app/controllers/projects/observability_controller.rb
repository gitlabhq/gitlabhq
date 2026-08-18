# frozen_string_literal: true

module Projects
  class ObservabilityController < Projects::ApplicationController
    include ::Observability::ShowActions
    include Gitlab::InternalEventsTracking

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
        @session_endpoint = bff_session_endpoint

        track_internal_event(
          'visit_project_observability_dashboard',
          user: current_user,
          project: project,
          namespace: project.namespace,
          additional_properties: { label: path }
        )

        respond_to do |format|
          format.html { render }
          format.json { render json: @data.to_h }
        end
      elsif project.group
        ancestor_group = highest_accessible_ancestor_group
        return render_404 unless ancestor_group

        redirect_to group_observability_setup_path(ancestor_group)
      elsif Ability.allowed?(current_user, :create_observability_access_request, project)
        redirect_to project_observability_setup_path(project)
      else
        render 'not_enabled'
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

    def bff_session_endpoint
      return unless ::Feature.enabled?(:observability_per_user_bff_auth, observability_setting&.group || project.group)

      project_observability_session_path(project)
    end

    def authorize_read_observability!
      return render_404 unless observability_feature_enabled?

      if project.group
        render_404 unless Ability.allowed?(current_user, :read_observability_portal, project.group)
      else
        render_404 unless Ability.allowed?(current_user, :read_observability_portal, project)
      end
    end

    def observability_feature_enabled?
      if project.group
        ::Feature.enabled?(:observability_sass_features, observability_setting&.group || project.group)
      else
        ::Feature.enabled?(:observability_saas_features_user_namespace, project.root_namespace)
      end
    end
  end
end
