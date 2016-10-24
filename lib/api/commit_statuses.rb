require 'mime/types'

module API
  # Project commit statuses API
  class CommitStatuses < Grape::API
    resource :projects do
      before { authenticate! }

      desc "Get a commit's statuses" do
        success Entities::CommitStatus
      end
      params do
        requires :id,    type: String, desc: 'The ID of a project'
        requires :sha,   type: String, desc: 'The commit hash'
        optional :ref,   type: String, desc: 'The ref'
        optional :stage, type: String, desc: 'The stage'
        optional :name,  type: String, desc: 'The name'
        optional :all,   type: String, desc: 'Show all statuses, default: false'
      end
      get ':id/repository/commits/:sha/statuses' do
        authorize!(:read_commit_status, user_project)

        not_found!('Commit') unless user_project.commit(params[:sha])

        pipelines = user_project.pipelines.where(sha: params[:sha])
        statuses = ::CommitStatus.where(pipeline: pipelines)
        statuses = statuses.latest unless to_boolean(params[:all])
        statuses = statuses.where(ref: params[:ref]) if params[:ref].present?
        statuses = statuses.where(stage: params[:stage]) if params[:stage].present?
        statuses = statuses.where(name: params[:name]) if params[:name].present?
        present paginate(statuses), with: Entities::CommitStatus
      end

      desc 'Post status to a commit' do
        success Entities::CommitStatus
      end
      params do
        requires :id,          type: String,  desc: 'The ID of a project'
        requires :sha,         type: String,  desc: 'The commit hash'
        requires :state,       type: String,  desc: 'The state of the status',
                               values: ['pending', 'running', 'success', 'failed', 'canceled']
        optional :ref,         type: String,  desc: 'The ref'
        optional :target_url,  type: String,  desc: 'The target URL to associate with this status'
        optional :description, type: String,  desc: 'A short description of the status'
        optional :name,        type: String,  desc: 'A string label to differentiate this status from the status of other systems. Default: "default"'
        optional :context,     type: String,  desc: 'A string label to differentiate this status from the status of other systems. Default: "default"'
      end
      post ':id/statuses/:sha' do
        authorize! :create_commit_status, user_project

        commit = @project.commit(params[:sha])
        not_found! 'Commit' unless commit

        # Since the CommitStatus is attached to Ci::Pipeline (in the future Pipeline)
        # We need to always have the pipeline object
        # To have a valid pipeline object that can be attached to specific MR
        # Other CI service needs to send `ref`
        # If we don't receive it, we will attach the CommitStatus to
        # the first found branch on that commit

        ref = params[:ref]
        ref ||= @project.repository.branch_names_contains(commit.sha).first
        not_found! 'References for commit' unless ref

        name = params[:name] || params[:context] || 'default'

        pipeline = @project.ensure_pipeline(ref, commit.sha, current_user)

        status = GenericCommitStatus.running_or_pending.find_or_initialize_by(
          project: @project,
          pipeline: pipeline,
          user: current_user,
          name: name,
          ref: ref,
          target_url: params[:target_url],
          description: params[:description]
        )

        begin
          case params[:state].to_s
          when 'pending'
            status.enqueue!
          when 'running'
            status.enqueue
            status.run!
          when 'success'
            status.success!
          when 'failed'
            status.drop!
          when 'canceled'
            status.cancel!
          else
            render_api_error!('invalid state', 400)
          end

          present status, with: Entities::CommitStatus
        rescue StateMachines::InvalidTransition => e
          render_api_error!(e.message, 400)
        end
      end
    end
  end
end
