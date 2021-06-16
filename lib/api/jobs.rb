# frozen_string_literal: true

module API
  class Jobs < ::API::Base
    include PaginationParams
    before { authenticate! }

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        requires :id, type: String, desc: 'The ID of a project'
      end

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
        success Entities::Ci::Job
      end
      params do
        use :optional_scope
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/jobs', feature_category: :continuous_integration do
        authorize_read_builds!

        builds = user_project.builds.order('id DESC')
        builds = filter_builds(builds, params[:scope])

        builds = builds.preload(:user, :job_artifacts_archive, :job_artifacts, :runner, :tags, pipeline: :project)
        present paginate(builds), with: Entities::Ci::Job
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a specific job of a project' do
        success Entities::Ci::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id', feature_category: :continuous_integration do
        authorize_read_builds!

        build = find_build!(params[:job_id])

        present build, with: Entities::Ci::Job
      end

      # TODO: We should use `present_disk_file!` and leave this implementation for backward compatibility (when build trace
      #       is saved in the DB instead of file). But before that, we need to consider how to replace the value of
      #       `runners_token` with some mask (like `xxxxxx`) when sending trace file directly by workhorse.
      desc 'Get a trace of a specific job of a project'
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id/trace', feature_category: :continuous_integration do
        authorize_read_builds!

        build = find_build!(params[:job_id])

        authorize_read_build_trace!(build) if build

        header 'Content-Disposition', "infile; filename=\"#{build.id}.log\""
        content_type 'text/plain'
        env['api.format'] = :binary

        # The trace can be nil bu body method expects a string as an argument.
        trace = build.trace.raw || ''
        body trace
      end

      desc 'Cancel a specific job of a project' do
        success Entities::Ci::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      post ':id/jobs/:job_id/cancel', feature_category: :continuous_integration do
        authorize_update_builds!

        build = find_build!(params[:job_id])
        authorize!(:update_build, build)

        build.cancel

        present build, with: Entities::Ci::Job
      end

      desc 'Retry a specific build of a project' do
        success Entities::Ci::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a build'
      end
      post ':id/jobs/:job_id/retry', feature_category: :continuous_integration do
        authorize_update_builds!

        build = find_build!(params[:job_id])
        authorize!(:update_build, build)
        break forbidden!('Job is not retryable') unless build.retryable?

        build = ::Ci::Build.retry(build, current_user)

        present build, with: Entities::Ci::Job
      end

      desc 'Erase job (remove artifacts and the trace)' do
        success Entities::Ci::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a build'
      end
      post ':id/jobs/:job_id/erase', feature_category: :continuous_integration do
        authorize_update_builds!

        build = find_build!(params[:job_id])
        authorize!(:erase_build, build)
        break forbidden!('Job is not erasable!') unless build.erasable?

        build.erase(erased_by: current_user)
        present build, with: Entities::Ci::Job
      end

      desc 'Trigger an actionable job (manual, delayed, etc)' do
        success Entities::Ci::JobBasic
        detail 'This feature was added in GitLab 8.11'
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a Job'
      end

      post ":id/jobs/:job_id/play", feature_category: :continuous_integration do
        authorize_read_builds!

        job = find_job!(params[:job_id])

        authorize!(:play_job, job)

        bad_request!("Unplayable Job") unless job.playable?

        job.play(current_user)

        status 200

        if job.is_a?(::Ci::Build)
          present job, with: Entities::Ci::Job
        else
          present job, with: Entities::Ci::Bridge
        end
      end
    end

    resource :job do
      desc 'Get current project using job token' do
        success Entities::Ci::Job
      end
      route_setting :authentication, job_token_allowed: true
      get '', feature_category: :continuous_integration do
        validate_current_authenticated_job

        present current_authenticated_job, with: Entities::Ci::Job
      end
    end

    helpers do
      # rubocop: disable CodeReuse/ActiveRecord
      def filter_builds(builds, scope)
        return builds if scope.nil? || scope.empty?

        available_statuses = ::CommitStatus::AVAILABLE_STATUSES

        unknown = scope - available_statuses
        render_api_error!('Scope contains invalid value(s)', 400) unless unknown.empty?

        builds.where(status: available_statuses && scope)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def validate_current_authenticated_job
        # current_authenticated_job will be nil if user is using
        # a valid authentication (like PRIVATE-TOKEN) that is not CI_JOB_TOKEN
        not_found!('Job') unless current_authenticated_job
      end
    end
  end
end

API::Jobs.prepend_mod_with('API::Jobs')
