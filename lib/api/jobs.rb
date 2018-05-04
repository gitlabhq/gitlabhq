module API
  class Jobs < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      helpers do
        params :optional_scope do
          optional :scope, types: [String, Array[String]], desc: 'The scope of builds to show',
                           values: ::CommitStatus::AVAILABLE_STATUSES,
                           coerce_with: ->(scope) {
                             case scope
                             when String
                               [scope]
                             when ::Hash
                               scope.values
                             when ::Array
                               scope
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

        builds = builds.preload(:user, :job_artifacts_archive, :runner, pipeline: :project)
        present paginate(builds), with: Entities::Job
      end

      desc 'Get pipeline jobs' do
        success Entities::Job
      end
      params do
        requires :pipeline_id, type: Integer,  desc: 'The pipeline ID'
        use :optional_scope
        use :pagination
      end
      get ':id/pipelines/:pipeline_id/jobs' do
        pipeline = user_project.pipelines.find(params[:pipeline_id])
        builds = pipeline.builds
        builds = filter_builds(builds, params[:scope])

        present paginate(builds), with: Entities::Job
      end

      desc 'Get a specific job of a project' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id' do
        authorize_read_builds!

        build = find_build!(params[:job_id])

        present build, with: Entities::Job
      end

      # TODO: We should use `present_disk_file!` and leave this implementation for backward compatibility (when build trace
      #       is saved in the DB instead of file). But before that, we need to consider how to replace the value of
      #       `runners_token` with some mask (like `xxxxxx`) when sending trace file directly by workhorse.
      desc 'Get a trace of a specific job of a project'
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id/trace' do
        authorize_read_builds!

        build = find_build!(params[:job_id])

        header 'Content-Disposition', "infile; filename=\"#{build.id}.log\""
        content_type 'text/plain'
        env['api.format'] = :binary

        trace = build.trace.raw
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

        build = find_build!(params[:job_id])
        authorize!(:update_build, build)

        build.cancel

        present build, with: Entities::Job
      end

      desc 'Retry a specific build of a project' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a build'
      end
      post ':id/jobs/:job_id/retry' do
        authorize_update_builds!

        build = find_build!(params[:job_id])
        authorize!(:update_build, build)
        break forbidden!('Job is not retryable') unless build.retryable?

        build = Ci::Build.retry(build, current_user)

        present build, with: Entities::Job
      end

      desc 'Erase job (remove artifacts and the trace)' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a build'
      end
      post ':id/jobs/:job_id/erase' do
        authorize_update_builds!

        build = find_build!(params[:job_id])
        authorize!(:erase_build, build)
        break forbidden!('Job is not erasable!') unless build.erasable?

        build.erase(erased_by: current_user)
        present build, with: Entities::Job
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

        build = find_build!(params[:job_id])

        authorize!(:update_build, build)
        bad_request!("Unplayable Job") unless build.playable?

        build.play(current_user)

        status 200
        present build, with: Entities::Job
      end
    end

    helpers do
      def filter_builds(builds, scope)
        return builds if scope.nil? || scope.empty?

        available_statuses = ::CommitStatus::AVAILABLE_STATUSES

        unknown = scope - available_statuses
        render_api_error!('Scope contains invalid value(s)', 400) unless unknown.empty?

        builds.where(status: available_statuses && scope)
      end
    end
  end
end
