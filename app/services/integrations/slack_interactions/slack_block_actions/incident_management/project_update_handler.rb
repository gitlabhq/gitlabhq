# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module SlackBlockActions
      module IncidentManagement
        class ProjectUpdateHandler
          include Gitlab::Utils::StrongMemoize

          def initialize(params, action)
            @view = params[:view]
            @action = action
            @team_id = params.dig(:view, :team_id)
            @user_id = params.dig(:user, :id)
          end

          def execute
            return if project_unchanged?
            return unless allowed?

            post_updated_modal
          end

          private

          def allowed?
            return false unless current_user

            current_user.can?(:read_project, old_project) &&
              current_user.can?(:read_project, new_project)
          end

          def current_user
            ChatNames::FindUserService.new(team_id, user_id).execute&.user
          end
          strong_memoize_attr :current_user

          def slack_installation
            SlackIntegration.with_bot.find_by_team_id(team_id)
          end
          strong_memoize_attr :slack_installation

          def post_updated_modal
            modal = update_modal

            begin
              response = ::Slack::API.new(slack_installation).post(
                'views.update',
                {
                  view_id: view[:id],
                  view: modal
                }
              )
            rescue *::Gitlab::HTTP::HTTP_ERRORS => e
              return ServiceResponse
                .error(message: 'HTTP exception when calling Slack API')
                .track_exception(
                  as: e.class,
                  slack_workspace_id: view[:team_id]
                )
            end

            return ServiceResponse.success(message: _('Modal updated')) if response['ok']

            ServiceResponse.error(
              message: _('Something went wrong while updating the modal.'),
              payload: response
            ).track_exception(
              response: response.to_h,
              slack_workspace_id: view[:team_id],
              slack_user_id: slack_installation.user_id
            )
          end

          def update_modal
            updated_view = update_incident_template
            cleanup(updated_view)
          end

          def update_incident_template
            updated_view = view.dup

            incident_description_blocks = updated_view[:blocks].select do |block|
              block[:block_id] == 'incident_description' || block[:block_id] == old_project.id.to_s
            end

            incident_description_blocks.first[:element][:initial_value] = read_template_content
            incident_description_blocks.first[:block_id] = new_project.id.to_s

            Integrations::SlackInteractions::IncidentManagement::IncidentModalOpenedService
              .cache_write(view[:id], new_project.id.to_s)

            updated_view
          end

          def new_project
            Project.find(action.dig(:selected_option, :value))
          end
          strong_memoize_attr :new_project

          def old_project
            old_project_id = Integrations::SlackInteractions::IncidentManagement::IncidentModalOpenedService
              .cache_read(view[:id])

            Project.find(old_project_id) if old_project_id
          end
          strong_memoize_attr :old_project

          def project_unchanged?
            old_project == new_project
          end

          def read_template_content
            new_project.incident_management_setting&.issue_template_content.to_s
          end

          def cleanup(view)
            view.except!(
              :id, :team_id, :state,
              :hash, :previous_view_id,
              :root_view_id, :app_id,
              :app_installed_team_id,
              :bot_id)
          end

          attr_accessor :view, :action, :team_id, :user_id
        end
      end
    end
  end
end
