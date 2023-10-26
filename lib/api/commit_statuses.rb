# frozen_string_literal: true

require 'mime/types'

module API
  class CommitStatuses < ::API::Base
    feature_category :continuous_integration
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      include PaginationParams

      before { authenticate! }

      desc "Get a commit's statuses" do
        success code: 200, model: Entities::CommitStatus
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
      end
      params do
        requires :sha,   type: String, desc: 'The commit hash', documentation: { example: '18f3e63d05582537db6d183d9d557be09e1f90c8' }
        optional :ref,   type: String, desc: 'The ref', documentation: { example: 'develop' }
        optional :stage, type: String, desc: 'The stage', documentation: { example: 'test' }
        optional :name,  type: String, desc: 'The name', documentation: { example: 'bundler:audit' }
        optional :all,   type: Boolean, desc: 'Show all statuses', documentation: { default: false }
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/repository/commits/:sha/statuses' do
        authorize!(:read_commit_status, user_project)

        not_found!('Commit') unless user_project.commit(params[:sha])

        pipelines = user_project.ci_pipelines.where(sha: params[:sha])
        statuses = ::CommitStatus.where(pipeline: pipelines)
        statuses = statuses.latest unless to_boolean(params[:all])
        statuses = statuses.where(ref: params[:ref]) if params[:ref].present?
        statuses = statuses.where(stage: params[:stage]) if params[:stage].present?
        statuses = statuses.where(name: params[:name]) if params[:name].present?
        present paginate(statuses), with: Entities::CommitStatus
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Post status to a commit' do
        success code: 200, model: Entities::CommitStatus
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha,          type: String, desc: 'The commit hash',
                                documentation: { example: '18f3e63d05582537db6d183d9d557be09e1f90c8' }
        requires :state,        type: String, desc: 'The state of the status',
                                values: %w[pending running success failed canceled],
                                documentation: { example: 'pending' }
        optional :ref,          type: String, desc: 'The ref',
                                documentation: { example: 'develop' }
        optional :target_url,   type: String, desc: 'The target URL to associate with this status',
                                documentation: { example: 'https://gitlab.example.com/janedoe/gitlab-foss/builds/91' }
        optional :description,  type: String, desc: 'A short description of the status'
        optional :name,         type: String, desc: 'A string label to differentiate this status from the status of other systems',
                                documentation: { example: 'coverage', default: 'default' }
        optional :context,      type: String, desc: 'A string label to differentiate this status from the status of other systems',
                                documentation: { example: 'coverage', default: 'default' }
        optional :coverage,     type: Float, desc: 'The total code coverage',
                                documentation: { example: 100.0 }
        optional :pipeline_id,  type: Integer, desc: 'An existing pipeline ID, when multiple pipelines on the same commit SHA have been triggered'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/statuses/:sha' do
        authorize! :create_commit_status, user_project

        response =
          ::Ci::CreateCommitStatusService
            .new(user_project, current_user, params)
            .execute(optional_commit_status_params: optional_commit_status_params)

        if response.error?
          render_api_error!(response.message, response.http_status)
        else
          present response.payload[:job], with: Entities::CommitStatus
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      helpers do
        def optional_commit_status_params
          updatable_optional_attributes = %w[target_url description coverage]
          attributes_for_keys(updatable_optional_attributes)
        end
      end
    end
  end
end
