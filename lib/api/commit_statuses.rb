# frozen_string_literal: true

require 'mime/types'

module API
  class CommitStatuses < ::API::Base
    feature_category :continuous_integration
    urgency :low

    ALLOWED_SORT_VALUES = %w[id pipeline_id].freeze
    DEFAULT_SORT_VALUE = 'id'

    ALLOWED_SORT_DIRECTIONS = %w[asc desc].freeze
    DEFAULT_SORT_DIRECTION = 'asc'

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
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
        requires :sha,   type: String, desc: 'Hash of the commit.', documentation: { example: '18f3e63d05582537db6d183d9d557be09e1f90c8' }
        optional :ref,   type: String, desc: 'Name of the branch or tag. Default is the default branch.', documentation: { example: 'develop' }
        optional :stage, type: String, desc: 'Filter statuses by build stage.', documentation: { example: 'test' }
        optional :name,  type: String, desc: 'Filter statuses by job name.', documentation: { example: 'bundler:audit' }
        optional :pipeline_id, type: Integer, desc: 'Filter statuses by pipeline ID.', documentation: { example: 1234 }
        optional :all, type: Boolean, desc: 'Include all statuses instead of latest only. Default is `false`.', documentation: { default: false }
        optional :order_by,
          type: String,
          values: ALLOWED_SORT_VALUES,
          default: DEFAULT_SORT_VALUE,
          desc: 'Values for sorting statuses. Valid values are `id` and `pipeline_id`. Default is `id`.',
          documentation: { default: DEFAULT_SORT_VALUE }
        optional :sort,
          type: String,
          values: ALLOWED_SORT_DIRECTIONS,
          desc: 'Sort statuses in ascending or descending order. Valid values are `asc` and `desc`. Default is `asc`.',
          documentation: { default: DEFAULT_SORT_DIRECTION }
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/repository/commits/:sha/statuses' do
        authorize!(:read_commit_status, user_project)

        not_found!('Commit') unless user_project.commit(params[:sha])

        pipelines = user_project.ci_pipelines.where(sha: params[:sha])
        pipelines = pipelines.where(id: params[:pipeline_id]) if params[:pipeline_id].present?
        statuses = ::CommitStatus.where(pipeline: pipelines)
        statuses = statuses.latest unless to_boolean(params[:all])
        statuses = statuses.where(ref: params[:ref]) if params[:ref].present?
        statuses = statuses.joins(:ci_stage).where(ci_stage: { name: params[:stage] }) if params[:stage].present?
        statuses = statuses.where(name: params[:name]) if params[:name].present?
        statuses = order_and_sort_statuses(statuses)
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
          values: %w[pending running success failed canceled skipped],
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
      helpers do
        def optional_commit_status_params
          updatable_optional_attributes = %w[target_url description coverage]
          attributes_for_keys(updatable_optional_attributes)
        end

        # rubocop: disable CodeReuse/ActiveRecord -- Better code maintainability here, this won't be reused anywhere
        def order_and_sort_statuses(statuses)
          sort_direction = params[:sort].presence || DEFAULT_SORT_DIRECTION
          order_column = ALLOWED_SORT_VALUES.include?(params[:order_by]) ? params[:order_by] : DEFAULT_SORT_VALUE
          statuses.order(order_column => sort_direction)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
