# frozen_string_literal: true

module Projects
  module Observability
    # Project-scoped equivalent of Groups::Observability::SessionsController.
    #
    # Resolves the observability setting via the project's namespace ancestry
    # (same as Projects::ObservabilityController) and mints a per-user SigNoz
    # session through the backend-for-frontend broker. No browser OAuth redirect.
    class SessionsController < Projects::ApplicationController
      include ::Observability::SessionActions

      private

      def observability_setting
        ::Observability::GroupO11ySetting.observability_setting_for(project)
      end
      strong_memoize_attr :observability_setting

      def feature_flag_group
        observability_setting&.group || project.group || project.root_namespace
      end

      def ensure_bff_enabled!
        render_404 unless ::Feature.enabled?(:observability_per_user_bff_auth, feature_flag_group)
      end

      def authorize_read_observability!
        return render_404 unless observability_feature_enabled?

        if project.group
          render_404 unless Ability.allowed?(current_user, :read_observability_portal, feature_flag_group)
        else
          render_404 unless Ability.allowed?(current_user, :read_observability_portal, project)
        end
      end

      def observability_feature_enabled?
        if project.group
          ::Feature.enabled?(:observability_sass_features, feature_flag_group)
        else
          ::Feature.enabled?(:observability_saas_features_user_namespace, project.root_namespace)
        end
      end

      # Mirrors the subject authorize_read_observability! evaluated the
      # Ability check against, so role resolution in O11yBffSession follows
      # the same access paths (group shares, inheritance, project team).
      def access_resource
        project.group ? feature_flag_group : project
      end
    end
  end
end
