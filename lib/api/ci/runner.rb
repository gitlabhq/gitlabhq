# frozen_string_literal: true

module API
  module Ci
    class Runner < ::API::Base
      helpers ::API::Helpers::Runner

      content_type :txt, 'text/plain'

      feature_category :runner

      resource :runners do
        desc 'Registers a new Runner' do
          success Entities::Ci::RunnerRegistrationDetails
          http_codes [[201, 'Runner was created'], [403, 'Forbidden']]
        end
        params do
          requires :token, type: String, desc: 'Registration token'
          optional :description, type: String, desc: %q(Runner's description)
          optional :info, type: Hash, desc: %q(Runner's metadata)
          optional :active, type: Boolean, desc: 'Should Runner be active'
          optional :locked, type: Boolean, desc: 'Should Runner be locked for current project'
          optional :access_level, type: String, values: ::Ci::Runner.access_levels.keys,
                                  desc: 'The access_level of the runner'
          optional :run_untagged, type: Boolean, desc: 'Should Runner handle untagged jobs'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: %q(List of Runner's tags)
          optional :maximum_timeout, type: Integer, desc: 'Maximum timeout set when this Runner will handle the job'
        end
        post '/' do
          attributes = attributes_for_keys([:description, :active, :locked, :run_untagged, :tag_list, :access_level, :maximum_timeout])
            .merge(get_runner_details_from_request)

          attributes =
            if runner_registration_token_valid?
              # Create shared runner. Requires admin access
              attributes.merge(runner_type: :instance_type)
            elsif runner_registrar_valid?('project') && @project = Project.find_by_runners_token(params[:token])
              # Create a specific runner for the project
              attributes.merge(runner_type: :project_type, projects: [@project])
            elsif runner_registrar_valid?('group') && @group = Group.find_by_runners_token(params[:token])
              # Create a specific runner for the group
              attributes.merge(runner_type: :group_type, groups: [@group])
            else
              forbidden!
            end

          @runner = ::Ci::Runner.create(attributes)

          if @runner.persisted?
            present @runner, with: Entities::Ci::RunnerRegistrationDetails
          else
            render_validation_error!(@runner)
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

          destroy_conditionally!(current_runner)
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
          body "200"
        end
      end

      resource :jobs do
        before { set_application_context }

        desc 'Request a job' do
          success Entities::Ci::JobRequest::Response
          http_codes [[201, 'Job was scheduled'],
                      [204, 'No job for Runner'],
                      [403, 'Forbidden']]
        end
        params do
          requires :token, type: String, desc: %q(Runner's authentication token)
          optional :last_update, type: String, desc: %q(Runner's queue last_update token)
          optional :info, type: Hash, desc: %q(Runner's metadata) do
            optional :name, type: String, desc: %q(Runner's name)
            optional :version, type: String, desc: %q(Runner's version)
            optional :revision, type: String, desc: %q(Runner's revision)
            optional :platform, type: String, desc: %q(Runner's platform)
            optional :architecture, type: String, desc: %q(Runner's architecture)
            optional :executor, type: String, desc: %q(Runner's executor)
            optional :features, type: Hash, desc: %q(Runner's features)
            optional :config, type: Hash, desc: %q(Runner's config) do
              optional :gpus, type: String, desc: %q(GPUs enabled)
            end
          end
          optional :session, type: Hash, desc: %q(Runner's session data) do
            optional :url, type: String, desc: %q(Session's url)
            optional :certificate, type: String, desc: %q(Session's certificate)
            optional :authorization, type: String, desc: %q(Session's authorization)
          end
          optional :job_age, type: Integer, desc: %q(Job should be older than passed age in seconds to be ran on runner)
        end

        # Since we serialize the build output ourselves to ensure Gitaly
        # gRPC calls succeed, we need a custom Grape format to handle
        # this:
        # 1. Grape will ordinarily call `JSON.dump` when Content-Type is set
        # to application/json. To avoid this, we need to define a custom type in
        # `content_type` and a custom formatter to go with it.
        # 2. Grape will parse the request input with the parser defined for
        # `content_type`. If no such parser exists, it will be treated as text. We
        # reuse the existing JSON parser to preserve the previous behavior.
        content_type :build_json, 'application/json'
        formatter :build_json, ->(object, _) { object }
        parser :build_json, ::Grape::Parser::Json

        post '/request' do
          authenticate_runner!

          unless current_runner.active?
            header 'X-GitLab-Last-Update', current_runner.ensure_runner_queue_value
            break no_content!
          end

          runner_params = declared_params(include_missing: false)

          if current_runner.runner_queue_value_latest?(runner_params[:last_update])
            header 'X-GitLab-Last-Update', runner_params[:last_update]
            Gitlab::Metrics.add_event(:build_not_found_cached)
            break no_content!
          end

          new_update = current_runner.ensure_runner_queue_value
          result = ::Ci::RegisterJobService.new(current_runner).execute(runner_params)

          if result.valid?
            if result.build_json
              Gitlab::Metrics.add_event(:build_found)
              env['api.format'] = :build_json
              body result.build_json
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
          http_codes [[200, 'Job was updated'],
                      [202, 'Update accepted'],
                      [400, 'Unknown parameters'],
                      [403, 'Forbidden']]
        end
        params do
          requires :token, type: String, desc: %q(Runners's authentication token)
          requires :id, type: Integer, desc: %q(Job's ID)
          optional :state, type: String, desc: %q(Job's status: success, failed)
          optional :checksum, type: String, desc: %q(Job's trace CRC32 checksum)
          optional :failure_reason, type: String, desc: %q(Job's failure_reason)
          optional :output, type: Hash, desc: %q(Build log state) do
            optional :checksum, type: String, desc: %q(Job's trace CRC32 checksum)
            optional :bytesize, type: Integer, desc: %q(Job's trace size in bytes)
          end
          optional :exit_code, type: Integer, desc: %q(Job's exit code)
        end
        put '/:id' do
          job = authenticate_job!

          Gitlab::Metrics.add_event(:update_build)

          service = ::Ci::UpdateBuildStateService
            .new(job, declared_params(include_missing: false))

          service.execute.then do |result|
            track_ci_minutes_usage!(job, current_runner)

            header 'X-GitLab-Trace-Update-Interval', result.backoff
            status result.status
            body result.status.to_s
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

          result = ::Ci::AppendBuildTraceService
            .new(job, content_range: content_range)
            .execute(request.body.read)

          if result.status == 403
            break error!('403 Forbidden', 403)
          end

          if result.status == 416
            break error!('416 Range Not Satisfiable', 416, { 'Range' => "0-#{result.stream_size}" })
          end

          track_ci_minutes_usage!(job, current_runner)

          status result.status
          header 'Job-Status', job.status
          header 'Range', "0-#{result.stream_size}"
          header 'X-GitLab-Trace-Update-Interval', job.trace.update_interval.to_s
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

          # NOTE:
          # In current runner, filesize parameter would be empty here. This is because archive is streamed by runner,
          # so the archive size is not known ahead of time. Streaming is done to not use additional I/O on
          # Runner to first save, and then send via Network.
          optional :filesize, type: Integer, desc: %q(Artifacts filesize)

          optional :artifact_type, type: String, desc: %q(The type of artifact),
                                  default: 'archive', values: ::Ci::JobArtifact.file_types.keys
        end
        post '/:id/artifacts/authorize' do
          not_allowed! unless Gitlab.config.artifacts.enabled
          require_gitlab_workhorse!

          job = authenticate_job!

          result = ::Ci::JobArtifacts::CreateService.new(job).authorize(artifact_type: params[:artifact_type], filesize: params[:filesize])

          if result[:status] == :success
            content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
            status :ok
            result[:headers]
          else
            render_api_error!(result[:message], result[:http_status])
          end
        end

        desc 'Upload artifacts for job' do
          success Entities::Ci::JobRequest::Response
          http_codes [[201, 'Artifact uploaded'],
                      [400, 'Bad request'],
                      [403, 'Forbidden'],
                      [405, 'Artifacts support not enabled'],
                      [413, 'File too large']]
        end
        params do
          requires :id, type: Integer, desc: %q(Job's ID)
          requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: %(The artifact file to store (generated by Multipart middleware))
          optional :token, type: String, desc: %q(Job's authentication token)
          optional :expire_in, type: String, desc: %q(Specify when artifacts should expire)
          optional :artifact_type, type: String, desc: %q(The type of artifact),
                                  default: 'archive', values: ::Ci::JobArtifact.file_types.keys
          optional :artifact_format, type: String, desc: %q(The format of artifact),
                                    default: 'zip', values: ::Ci::JobArtifact.file_formats.keys
          optional :metadata, type: ::API::Validations::Types::WorkhorseFile, desc: %(The artifact metadata to store (generated by Multipart middleware))
        end
        post '/:id/artifacts' do
          not_allowed! unless Gitlab.config.artifacts.enabled
          require_gitlab_workhorse!

          job = authenticate_job!

          artifacts = params[:file]
          metadata = params[:metadata]

          result = ::Ci::JobArtifacts::CreateService.new(job).execute(artifacts, params, metadata_file: metadata)

          if result[:status] == :success
            status :created
            body "201"
          else
            render_api_error!(result[:message], result[:http_status])
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
          job = authenticate_job!(require_running: false)

          present_carrierwave_file!(job.artifacts_file, supports_direct_download: params[:direct_download])
        end
      end
    end
  end
end
