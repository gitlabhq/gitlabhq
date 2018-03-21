module API
  class Runner < Grape::API
    helpers ::API::Helpers::Runner

    resource :runners do
      desc 'Registers a new Runner' do
        success Entities::RunnerRegistrationDetails
        http_codes [[201, 'Runner was created'], [403, 'Forbidden']]
      end
      params do
        requires :token, type: String, desc: 'Registration token'
        optional :description, type: String, desc: %q(Runner's description)
        optional :info, type: Hash, desc: %q(Runner's metadata)
        optional :locked, type: Boolean, desc: 'Should Runner be locked for current project'
        optional :run_untagged, type: Boolean, desc: 'Should Runner handle untagged jobs'
        optional :tag_list, type: Array[String], desc: %q(List of Runner's tags)
        optional :maximum_timeout, type: Integer, desc: 'Maximum timeout set when this Runner will handle the job'
      end
      post '/' do
        attributes = attributes_for_keys([:description, :locked, :run_untagged, :tag_list, :maximum_timeout])
          .merge(get_runner_details_from_request)

        runner =
          if runner_registration_token_valid?
            # Create shared runner. Requires admin access
            Ci::Runner.create(attributes.merge(is_shared: true))
          elsif project = Project.find_by(runners_token: params[:token])
            # Create a specific runner for project.
            project.runners.create(attributes)
          end

        return forbidden! unless runner

        if runner.id
          present runner, with: Entities::RunnerRegistrationDetails
        else
          not_found!
        end
      end

      desc 'Deletes a registered Runner' do
        http_codes [[204, 'Runner was deleted'], [403, 'Forbidden']]
      end
      params do
        requires :token, type: String, desc: %q(Runner's authentication token)
      end
      delete '/' do
        authenticate_runner!

        runner = Ci::Runner.find_by_token(params[:token])

        destroy_conditionally!(runner)
      end

      desc 'Validates authentication credentials' do
        http_codes [[200, 'Credentials are valid'], [403, 'Forbidden']]
      end
      params do
        requires :token, type: String, desc: %q(Runner's authentication token)
      end
      post '/verify' do
        authenticate_runner!
        status 200
      end
    end

    resource :jobs do
      desc 'Request a job' do
        success Entities::JobRequest::Response
        http_codes [[201, 'Job was scheduled'],
                    [204, 'No job for Runner'],
                    [403, 'Forbidden']]
      end
      params do
        requires :token, type: String, desc: %q(Runner's authentication token)
        optional :last_update, type: String, desc: %q(Runner's queue last_update token)
        optional :info, type: Hash, desc: %q(Runner's metadata)
      end
      post '/request' do
        authenticate_runner!
        no_content! unless current_runner.active?

        if current_runner.runner_queue_value_latest?(params[:last_update])
          header 'X-GitLab-Last-Update', params[:last_update]
          Gitlab::Metrics.add_event(:build_not_found_cached)
          return no_content!
        end

        new_update = current_runner.ensure_runner_queue_value
        result = ::Ci::RegisterJobService.new(current_runner).execute

        if result.valid?
          if result.build
            Gitlab::Metrics.add_event(:build_found,
                                      project: result.build.project.full_path)
            present result.build, with: Entities::JobRequest::Response
          else
            Gitlab::Metrics.add_event(:build_not_found)
            header 'X-GitLab-Last-Update', new_update
            no_content!
          end
        else
          # We received build that is invalid due to concurrency conflict
          Gitlab::Metrics.add_event(:build_invalid)
          conflict!
        end
      end

      desc 'Updates a job' do
        http_codes [[200, 'Job was updated'], [403, 'Forbidden']]
      end
      params do
        requires :token, type: String, desc: %q(Runners's authentication token)
        requires :id, type: Integer, desc: %q(Job's ID)
        optional :trace, type: String, desc: %q(Job's full trace)
        optional :state, type: String, desc: %q(Job's status: success, failed)
        optional :failure_reason, type: String, values: CommitStatus.failure_reasons.keys,
                                  desc: %q(Job's failure_reason)
      end
      put '/:id' do
        job = authenticate_job!

        job.trace.set(params[:trace]) if params[:trace]

        Gitlab::Metrics.add_event(:update_build,
                                  project: job.project.full_path)

        case params[:state].to_s
        when 'success'
          job.success
        when 'failed'
          job.drop(params[:failure_reason] || :unknown_failure)
        end
      end

      desc 'Appends a patch to the job trace' do
        http_codes [[202, 'Trace was patched'],
                    [400, 'Missing Content-Range header'],
                    [403, 'Forbidden'],
                    [416, 'Range not satisfiable']]
      end
      params do
        requires :id, type: Integer, desc: %q(Job's ID)
        optional :token, type: String, desc: %q(Job's authentication token)
      end
      patch '/:id/trace' do
        job = authenticate_job!

        error!('400 Missing header Content-Range', 400) unless request.headers.key?('Content-Range')
        content_range = request.headers['Content-Range']
        content_range = content_range.split('-')

        stream_size = job.trace.append(request.body.read, content_range[0].to_i)
        if stream_size < 0
          return error!('416 Range Not Satisfiable', 416, { 'Range' => "0-#{-stream_size}" })
        end

        status 202
        header 'Job-Status', job.status
        header 'Range', "0-#{stream_size}"
      end

      desc 'Authorize artifacts uploading for job' do
        http_codes [[200, 'Upload allowed'],
                    [403, 'Forbidden'],
                    [405, 'Artifacts support not enabled'],
                    [413, 'File too large']]
      end
      params do
        requires :id, type: Integer, desc: %q(Job's ID)
        optional :token, type: String, desc: %q(Job's authentication token)
        optional :filesize, type: Integer, desc: %q(Artifacts filesize)
      end
      post '/:id/artifacts/authorize' do
        not_allowed! unless Gitlab.config.artifacts.enabled
        require_gitlab_workhorse!
        Gitlab::Workhorse.verify_api_request!(headers)

        job = authenticate_job!
        forbidden!('Job is not running') unless job.running?

        if params[:filesize]
          file_size = params[:filesize].to_i
          file_to_large! unless file_size < max_artifacts_size
        end

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
        Gitlab::Workhorse.artifact_upload_ok
      end

      desc 'Upload artifacts for job' do
        success Entities::JobRequest::Response
        http_codes [[201, 'Artifact uploaded'],
                    [400, 'Bad request'],
                    [403, 'Forbidden'],
                    [405, 'Artifacts support not enabled'],
                    [413, 'File too large']]
      end
      params do
        requires :id, type: Integer, desc: %q(Job's ID)
        optional :token, type: String, desc: %q(Job's authentication token)
        optional :expire_in, type: String, desc: %q(Specify when artifacts should expire)
        optional :file, type: File, desc: %q(Artifact's file)
        optional 'file.path', type: String, desc: %q(path to locally stored body (generated by Workhorse))
        optional 'file.name', type: String, desc: %q(real filename as send in Content-Disposition (generated by Workhorse))
        optional 'file.type', type: String, desc: %q(real content type as send in Content-Type (generated by Workhorse))
        optional 'file.sha256', type: String, desc: %q(sha256 checksum of the file)
        optional 'metadata.path', type: String, desc: %q(path to locally stored body (generated by Workhorse))
        optional 'metadata.name', type: String, desc: %q(filename (generated by Workhorse))
      end
      post '/:id/artifacts' do
        not_allowed! unless Gitlab.config.artifacts.enabled
        require_gitlab_workhorse!

        job = authenticate_job!
        forbidden!('Job is not running!') unless job.running?

        workhorse_upload_path = JobArtifactUploader.workhorse_upload_path
        artifacts = uploaded_file(:file, workhorse_upload_path)
        metadata = uploaded_file(:metadata, workhorse_upload_path)

        bad_request!('Missing artifacts file!') unless artifacts
        file_to_large! unless artifacts.size < max_artifacts_size

        expire_in = params['expire_in'] ||
          Gitlab::CurrentSettings.current_application_settings.default_artifacts_expire_in

        job.build_job_artifacts_archive(project: job.project, file_type: :archive, file: artifacts, file_sha256: params['file.sha256'], expire_in: expire_in)
        job.build_job_artifacts_metadata(project: job.project, file_type: :metadata, file: metadata, expire_in: expire_in) if metadata
        job.artifacts_expire_in = expire_in

        if job.save
          present job, with: Entities::JobRequest::Response
        else
          render_validation_error!(job)
        end
      end

      desc 'Download the artifacts file for job' do
        http_codes [[200, 'Upload allowed'],
                    [403, 'Forbidden'],
                    [404, 'Artifact not found']]
      end
      params do
        requires :id, type: Integer, desc: %q(Job's ID)
        optional :token, type: String, desc: %q(Job's authentication token)
        optional :direct_download, default: false, type: Boolean, desc: %q(Perform direct download from remote storage instead of proxying artifacts)
      end
      get '/:id/artifacts' do
        job = authenticate_job!

        present_carrierwave_file!(job.artifacts_file, supports_direct_download: params[:direct_download])
      end
    end
  end
end
