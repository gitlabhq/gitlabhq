# frozen_string_literal: true

module API
  module Helpers
    module UsageDataHelpers
      extend Grape::API::Helpers

      params :event_params do
        requires :event, type: String, desc: 'The event name that should be tracked',
          documentation: { example: 'i_quickactions_page' }
        optional :namespace_id, type: Integer, desc: 'Namespace ID',
          documentation: { example: 1234 }
        optional :project_id, type: Integer, desc: 'Project ID',
          documentation: { example: 1234 }
        optional :project_path, type: String, desc: 'Project path (used to resolve project_id if not provided)',
          documentation: { example: 'namespace/project' }
        mutually_exclusive :project_id, :project_path
        optional :additional_properties, type: Hash, desc: 'Additional properties to be tracked',
          documentation: { example: { label: 'login_button', value: 1 } }
        optional :send_to_snowplow, type: Boolean, desc: 'Send the tracked event to Snowplow',
          documentation: { example: true, default: false }
      end

      def process_event(params, resolved_projects = {})
        event_name = params[:event]
        namespace_id = params[:namespace_id]
        project_id = params[:project_id]
        additional_properties = params.fetch(:additional_properties, {}).symbolize_keys
        send_snowplow_event = !!params[:send_to_snowplow]

        # Resolve project from project_path if provided
        if params[:project_path].present?
          resolved_project = resolved_projects[params[:project_path]]

          if resolved_project.nil?
            resolved_project = ::ProjectsFinder.new(
              params: { full_paths: [params[:project_path]] },
              current_user: current_user
            ).execute.first
          end

          if resolved_project
            project_id = resolved_project.id
            namespace_id ||= resolved_project.namespace_id
          end
        end

        track_event(
          event_name,
          send_snowplow_event: send_snowplow_event,
          user: current_user,
          namespace_id: namespace_id,
          project_id: project_id,
          additional_properties: additional_properties
        )
      end
    end
  end
end
