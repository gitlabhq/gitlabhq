# frozen_string_literal: true

module API
  class UserRunners < ::API::Base
    include APIGuard

    helpers ::API::Ci::Helpers::RunnerHelpers
    allow_access_with_scope :create_runner, if: ->(request) { request.post? }

    resource :user do
      before do
        authenticate!
      end

      desc 'Create a runner owned by currently authenticated user' do
        detail 'Create a new runner'
        success Entities::Ci::RunnerRegistrationDetails
        failure [[400, 'Bad Request'], [403, 'Forbidden']]
        tags %w[users runners]
      end
      params do
        requires :runner_type, type: String, values: ::Ci::Runner.runner_types.keys,
          desc: 'Scope of the runner.'
        given runner_type: ->(runner_type) { runner_type == 'group_type' } do
          requires :group_id, type: Integer,
            desc: 'ID of the group to create the runner in. Required if `runner_type` is `group_type`.',
            documentation: { example: 1 }
        end
        given runner_type: ->(runner_type) { runner_type == 'project_type' } do
          requires :project_id, type: Integer,
            desc: 'ID of the project to create the runner in. Required if `runner_type` is `project_type`.',
            documentation: { example: 1 }
        end
        optional :description, type: String, desc: 'Description of the runner.'
        optional :maintenance_note, type: String,
          desc: 'Free-form maintenance notes for the runner. Limited to 1024 characters.'
        optional :paused, type: Boolean, desc: 'If `true`, the runner ignores new jobs.'
        optional :locked, type: Boolean, default: false,
          desc: 'Specifies if the runner should be locked for the current project.'
        optional :access_level, type: String, values: ::Ci::Runner.access_levels.keys,
          desc: 'Access level of the runner.'
        optional :run_untagged, type: Boolean, default: true,
          desc: 'Specifies if the runner should handle untagged jobs.'
        optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          desc: 'Comma-separated list of runner tags.'
        optional :maximum_timeout, type: Integer,
          desc: 'Maximum time, in seconds, that runners can spend running a job.'

        use :create_runner_params_ee
      end
      route_setting :authorization, permissions: :create_runner, boundary_type: :user
      post 'runners', urgency: :low, feature_category: :fleet_visibility do
        attributes = attributes_for_keys(
          %i[runner_type group_id project_id description maintenance_note paused locked run_untagged tag_list
            access_level maximum_timeout token_expires_at token_rotation_deadline]
        )

        case attributes[:runner_type]
        when 'group_type'
          attributes[:scope] = ::Group.find_by_id(attributes.delete(:group_id))
        when 'project_type'
          attributes[:scope] = ::Project.find_by_id(attributes.delete(:project_id))
        end

        result = ::Ci::Runners::CreateRunnerService.new(user: current_user, params: attributes).execute
        if result.error?
          message = result.errors.to_sentence
          forbidden!(message) if result.reason == :forbidden
          bad_request!(message)
        end

        present result.payload[:runner], with: Entities::Ci::RunnerRegistrationDetails
      end
    end
  end
end
