require 'mime/types'

module API
  # Project commit statuses API
  class CommitStatuses < Grape::API
    resource :projects do
      before { authenticate! }

      # Get a commit's statuses
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit hash
      #   ref (optional) - The ref
      #   stage (optional) - The stage
      #   name (optional) - The name
      #   all (optional) - Show all statuses, default: false
      # Examples:
      #   GET /projects/:id/repository/commits/:sha/statuses
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

      # Post status to commit
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The commit hash
      #   ref (optional) - The ref
      #   state (required) - The state of the status. Can be: pending, running, success, failed or canceled
      #   target_url (optional) - The target URL to associate with this status
      #   description (optional) - A short description of the status
      #   name or context (optional) - A string label to differentiate this status from the status of other systems. Default: "default"
      # Examples:
      #   POST /projects/:id/statuses/:sha
      post ':id/statuses/:sha' do
        authorize! :create_commit_status, user_project
        required_attributes! [:state]
        attrs = attributes_for_keys [:target_url, :description]
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

        pipeline = @project.ensure_pipeline(commit.sha, ref, current_user)

        status = GenericCommitStatus.running_or_pending.find_or_initialize_by(
          project: @project, pipeline: pipeline,
          user: current_user, name: name, ref: ref)
        status.attributes = attrs

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
