# frozen_string_literal: true

module Observability
  module SetupActions
    extend ActiveSupport::Concern

    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- view layer requires @namespace, @has_pipelines_since_setup, @export_variable
    def show
      @namespace = observability_namespace

      if @namespace.observability_group_o11y_setting.present?
        @has_pipelines_since_setup =
          ::Observability::PipelinesSinceSetupExist
            .new(@namespace)
            .execute
        @export_variable = @namespace.observability_group_o11y_setting
          .observability_export_variable_for(project_for_export_variable)
        return
      end

      @namespace.build_observability_group_o11y_setting(o11y_service_name: @namespace.id) if provisioning?
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    private

    def provisioning?
      params.permit(:provisioning)[:provisioning] == 'true'
    end

    # Subclasses must define:
    #   observability_namespace - the Group or personal Namespace
    def observability_namespace
      raise NotImplementedError
    end

    def project_for_export_variable
      nil
    end
  end
end
