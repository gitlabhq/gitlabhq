# frozen_string_literal: true

module API
  class UserRunners < ::API::Base
    include APIGuard

    allow_access_with_scope :create_runner, if: ->(request) { request.post? }

    resource :user do
      before do
        authenticate!
      end

      desc 'Create a runner owned by currently authenticated user' do
        detail 'Create a new runner'
        success Entities::Ci::RunnerRegistrationDetails
        failure [[400, 'Bad Request'], [403, 'Forbidden']]
        tags %w[user runners]
      end
      params do
        requires :runner_type, type: String, values: ::Ci::Runner.runner_types.keys,
          desc: 'Specifies the scope of the runner'
        given runner_type: ->(runner_type) { runner_type == 'group_type' } do
          requires :group_id, type: Integer,
            desc: 'The ID of the group that the runner is created in',
            documentation: { example: 1 }
        end
        given runner_type: ->(runner_type) { runner_type == 'project_type' } do
          requires :project_id, type: Integer,
            desc: 'The ID of the project that the runner is created in',
            documentation: { example: 1 }
        end
        optional :description, type: String, desc: 'Description of the runner'
        optional :maintenance_note, type: String,
          desc: 'Free-form maintenance notes for the runner (1024 characters)'
        optional :paused, type: Boolean, desc: 'Specifies if the runner should ignore new jobs (defaults to false)'
        optional :locked, type: Boolean,
          desc: 'Specifies if the runner should be locked for the current project (defaults to false)'
        optional :access_level, type: String, values: ::Ci::Runner.access_levels.keys,
          desc: 'The access level of the runner'
        optional :run_untagged, type: Boolean,
          desc: 'Specifies if the runner should handle untagged jobs  (defaults to true)'
        optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          desc: 'A list of runner tags'
        optional :maximum_timeout, type: Integer,
          desc: 'Maximum timeout that limits the amount of time (in seconds) that runners can run jobs'
      end
      post 'runners', urgency: :low, feature_category: :fleet_visibility do
        attributes = attributes_for_keys(
          %i[runner_type group_id project_id description maintenance_note paused locked run_untagged tag_list
            access_level maximum_timeout]
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
