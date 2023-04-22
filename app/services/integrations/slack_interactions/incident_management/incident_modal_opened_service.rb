# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module IncidentManagement
      class IncidentModalOpenedService
        MAX_PROJECTS = 100
        CACHE_EXPIRES_IN = 5.minutes

        def initialize(slack_installation, current_user, params)
          @slack_installation = slack_installation
          @current_user = current_user
          @team_id = params[:team_id]
          @response_url = params[:response_url]
          @trigger_id = params[:trigger_id]
        end

        def execute
          if user_projects.empty?
            return ServiceResponse.error(message: _('You do not have access to any projects for creating incidents.'))
          end

          post_modal
        end

        def self.cache_write(view_id, project_id)
          Rails.cache.write(cache_build_key(view_id), project_id, expires_in: CACHE_EXPIRES_IN)
        end

        def self.cache_read(view_id)
          Rails.cache.read(cache_build_key(view_id))
        end

        private

        attr_reader :slack_installation, :current_user, :team_id, :response_url, :trigger_id

        def self.cache_build_key(view_id)
          "slack:incident_modal_opened:#{view_id}"
        end

        def user_projects
          current_user.projects_where_can_admin_issues.limit(MAX_PROJECTS)
        end

        def post_modal
          begin
            response = ::Slack::API.new(slack_installation).post(
              'views.open',
              modal_view
            )
          rescue *Gitlab::HTTP::HTTP_ERRORS => e
            return ServiceResponse
              .error(message: 'HTTP exception when calling Slack API')
              .track_exception(
                as: e.class,
                slack_workspace_id: team_id
              )
          end

          if response['ok']
            self.class.cache_write(view_id(response), project_id(response))

            return ServiceResponse.success(message: _('Please complete the incident creation form.'))
          end

          ServiceResponse.error(
            message: _('Something went wrong while opening the incident form.'),
            payload: response
          ).track_exception(
            response: response.to_h,
            slack_workspace_id: team_id,
            slack_user_id: slack_installation.user_id
          )
        end

        def modal_view
          {
            trigger_id: trigger_id,
            view: modal_payload
          }
        end

        def modal_payload
          ::Slack::BlockKit::IncidentManagement::IncidentModalOpened.new(
            user_projects,
            response_url
          ).build
        end

        def project_id(response)
          response.dig(
            'view', 'state', 'values',
            'project_and_severity_selector',
            'incident_management_project', 'selected_option',
            'value')
        end

        def view_id(response)
          response.dig('view', 'id')
        end
      end
    end
  end
end
