# frozen_string_literal: true

module Projects
  module Observability
    class BaseController < Projects::ApplicationController
      before_action :authenticate_user!
      before_action :redirect_group_projects!
      before_action :authorize_request_access!

      feature_category :observability
      urgency :low

      private

      # Group projects have a canonical setup surface at the group level.
      # These project-level routes only serve personal-namespace projects;
      # the group controllers enforce their own feature flag and abilities.
      def redirect_group_projects!
        redirect_to group_observability_setup_path(project.group) if project.group
      end

      def authorize_request_access!
        return render_404 unless ::Feature.enabled?(:observability_sass_features, project.root_namespace)

        return if Ability.allowed?(current_user, :create_observability_access_request, project)

        render_404
      end
    end
  end
end
