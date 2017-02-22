module API
  class Jobs < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      helpers do
        params :optional_scope do
          optional :scope, types: [String, Array[String]], desc: 'The scope of builds to show',
                           values: ::CommitStatus::AVAILABLE_STATUSES,
                           coerce_with: ->(scope) {
                             case scope
                             when String
                               [scope]
                             when Hashie::Mash
                               scope.values
                             else
                               ['unknown']
                             end
                           }
        end
      end

      desc 'Get a projects jobs' do
        success Entities::Job
      end
      params do
        use :optional_scope
        use :pagination
      end
      get ':id/jobs' do
        builds = user_project.builds.order('id DESC')
        builds = filter_builds(builds, params[:scope])

        present paginate(builds), with: Entities::Job,
                                  user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Get jobs for a specific commit of a project' do
        success Entities::Job
      end
      params do
        requires :sha, type: String, desc: 'The SHA id of a commit'
        use :optional_scope
        use :pagination
      end
      get ':id/repository/commits/:sha/jobs' do
        authorize_read_builds!

        return not_found! unless user_project.commit(params[:sha])

        pipelines = user_project.pipelines.where(sha: params[:sha])
        builds = user_project.builds.where(pipeline: pipelines).order('id DESC')
        builds = filter_builds(builds, params[:scope])

        present paginate(builds), with: Entities::Job,
                                  user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Get a specific job of a project' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id' do
        authorize_read_builds!

        build = get_build!(params[:job_id])

        present build, with: Entities::Job,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Download the artifacts file from a job' do
        detail 'This feature was introduced in GitLab 8.5'
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id/artifacts' do
        authorize_read_builds!

        build = get_build!(params[:job_id])

        present_artifacts!(build.artifacts_file)
      end

      desc 'Download the artifacts file from a job' do
        detail 'This feature was introduced in GitLab 8.10'
      end
      params do
        requires :ref_name, type: String, desc: 'The ref from repository'
        requires :job,      type: String, desc: 'The name for the job'
      end
      get ':id/jobs/artifacts/:ref_name/download',
        requirements: { ref_name: /.+/ } do
        authorize_read_builds!

        builds = user_project.latest_successful_builds_for(params[:ref_name])
        latest_build = builds.find_by!(name: params[:job])

        present_artifacts!(latest_build.artifacts_file)
      end

      # TODO: We should use `present_file!` and leave this implementation for backward compatibility (when build trace
      #       is saved in the DB instead of file). But before that, we need to consider how to replace the value of
      #       `runners_token` with some mask (like `xxxxxx`) when sending trace file directly by workhorse.
      desc 'Get a trace of a specific job of a project'
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id/trace' do
        authorize_read_builds!

        build = get_build!(params[:job_id])

        header 'Content-Disposition', "infile; filename=\"#{build.id}.log\""
        content_type 'text/plain'
        env['api.format'] = :binary

        trace = build.trace
        body trace
      end

      desc 'Cancel a specific job of a project' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      post ':id/jobs/:job_id/cancel' do
        authorize_update_builds!

        build = get_build!(params[:job_id])

        build.cancel

        present build, with: Entities::Job,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Retry a specific build of a project' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a build'
      end
      post ':id/jobs/:job_id/retry' do
        authorize_update_builds!

        build = get_build!(params[:job_id])
        return forbidden!('Job is not retryable') unless build.retryable?

        build = Ci::Build.retry(build, current_user)

        present build, with: Entities::Job,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Erase job (remove artifacts and the trace)' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a build'
      end
      post ':id/jobs/:job_id/erase' do
        authorize_update_builds!

        build = get_build!(params[:job_id])
        return forbidden!('Job is not erasable!') unless build.erasable?

        build.erase(erased_by: current_user)
        present build, with: Entities::Job,
                       user_can_download_artifacts: can?(current_user, :download_build_artifacts, user_project)
      end

      desc 'Keep the artifacts to prevent them from being deleted' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      post ':id/jobs/:job_id/artifacts/keep' do
        authorize_update_builds!

        build = get_build!(params[:job_id])
        return not_found!(build) unless build.artifacts?

        build.keep_artifacts!

        status 200
        present build, with: Entities::Job,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Trigger a manual job' do
        success Entities::Job
        detail 'This feature was added in GitLab 8.11'
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a Job'
      end
      post ":id/jobs/:job_id/play" do
        authorize_read_builds!

        build = get_build!(params[:job_id])

        bad_request!("Unplayable Job") unless build.playable?

        build.play(current_user)

        status 200
        present build, with: Entities::Job,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end
    end

    helpers do
      def get_build(id)
        user_project.builds.find_by(id: id.to_i)
      end

      def get_build!(id)
        get_build(id) || not_found!
      end

      def present_artifacts!(artifacts_file)
        if !artifacts_file.file_storage?
          redirect_to(build.artifacts_file.url)
        elsif artifacts_file.exists?
          present_file!(artifacts_file.path, artifacts_file.filename)
        else
          not_found!
        end
      end

      def filter_builds(builds, scope)
        return builds if scope.nil? || scope.empty?

        available_statuses = ::CommitStatus::AVAILABLE_STATUSES

        unknown = scope - available_statuses
        render_api_error!('Scope contains invalid value(s)', 400) unless unknown.empty?

        builds.where(status: available_statuses && scope)
      end

      def authorize_read_builds!
        authorize! :read_build, user_project
      end

      def authorize_update_builds!
        authorize! :update_build, user_project
      end
    end
  end
end
