# frozen_string_literal: true

module Observability
  module SetupActions
    extend ActiveSupport::Concern
    include Gitlab::InternalEventsTracking

    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- view layer requires @namespace, @has_pipelines_since_setup, @export_variable
    def show
      @namespace = observability_namespace

      track_internal_event(
        'visit_observability_setup_page',
        user: current_user,
        namespace: @namespace,
        additional_properties: { label: observability_context_label }
      )

      if @namespace.observability_group_o11y_setting.present?
        begin
          @has_pipelines_since_setup =
            ::Observability::PipelinesSinceSetupExist
              .new(@namespace)
              .execute
        rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- graceful degradation when pipeline existence check times out
          Gitlab::ErrorTracking.track_exception(e, group_id: @namespace.id)
          @has_pipelines_since_setup = false
        end

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

    # Subclasses must define:
    #   observability_context_label - "group" or "project", used for tracking
    def observability_context_label
      raise NotImplementedError
    end
  end
end
