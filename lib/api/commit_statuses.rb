require 'mime/types'

module API
  # Project commit statuses API
  class CommitStatus < Grape::API
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
        authorize! :read_commit_statuses, user_project
        sha = params[:sha]
        ci_commit = user_project.ci_commit(sha)
        not_found! 'Commit' unless ci_commit
        statuses = ci_commit.statuses
        statuses = statuses.latest unless parse_boolean(params[:all])
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
      #   state (required) - The state of the status. Can be: pending, running, success, error or failure
      #   target_url (optional) - The target URL to associate with this status
      #   description (optional) - A short description of the status
      #   name or context (optional) - A string label to differentiate this status from the status of other systems. Default: "default"
      # Examples:
      #   POST /projects/:id/statuses/:sha
      post ':id/statuses/:sha' do
        authorize! :create_commit_status, user_project
        required_attributes! [:state]
        attrs = attributes_for_keys [:ref, :target_url, :description, :context, :name]
        commit = @project.commit(params[:sha])
        not_found! 'Commit' unless commit

        ci_commit = @project.ensure_ci_commit(commit.sha)

        name = params[:name] || params[:context]
        status = GenericCommitStatus.running_or_pending.find_by(commit: ci_commit, name: name, ref: params[:ref])
        status ||= GenericCommitStatus.new(commit: ci_commit, user: current_user)
        status.update(attrs)

        case params[:state].to_s
        when 'running'
          status.run
        when 'success'
          status.success
        when 'failed'
          status.drop
        when 'canceled'
          status.cancel
        else
          status.status = params[:state].to_s
        end

        if status.save
          present status, with: Entities::CommitStatus
        else
          render_validation_error!(status)
        end
      end
    end
  end
end
