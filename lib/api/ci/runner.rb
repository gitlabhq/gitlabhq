# frozen_string_literal: true

module API
  module Ci
    class Runner < ::API::Base
      # Runner endpoints set Current.organization to the runner's own
      # organization from within the endpoint body (via authenticate_runner!).
      # Disable the global fallback in API::API's before_validation hook so it
      # does not pre-empt that assignment with the default organization.
      skip_global_organization_setup!

      helpers ::API::Ci::Helpers::Runner

      content_type :txt, 'text/plain'

      before { check_if_backoff_required! }

      resource :runners do
        desc 'Create a runner' do
          detail 'Creates a runner.'
          tags ['ci_runners']
          success Entities::Ci::RunnerRegistrationDetails
          failure [[400, 'Bad Request'], [403, 'Forbidden'], [410, 'Gone']]
        end
        params do
          requires :token, type: String, desc: 'Registration token'
          optional :description, type: String, desc: 'Description of the runner'
          optional :maintainer_note, type: String, desc: 'Deprecated: see `maintenance_note`'
          optional :maintenance_note, type: String,
            desc: 'Free-form maintenance notes for the runner (1024 characters)'
          optional :info, type: Hash, desc: "Runner's metadata" do
            optional :name, type: String, desc: "Runner's name"
            optional :version, type: String, desc: "Runner's version"
            optional :revision, type: String, desc: "Runner's revision"
            optional :platform, type: String, desc: "Runner's platform"
            optional :architecture, type: String, desc: "Runner's architecture"
          end
          optional :active, type: Boolean,
            desc: 'Deprecated: Use `paused` instead. Specifies if the runner is allowed ' \
                  'to receive new jobs'
          optional :paused, type: Boolean, desc: 'Specifies if the runner should ignore new jobs'
          optional :locked, type: Boolean, desc: 'Specifies if the runner should be locked for the current project'
          optional :access_level, type: String, values: ::Ci::Runner.access_levels.keys,
            desc: 'The access level of the runner'
          optional :run_untagged, type: Boolean, desc: 'Specifies if the runner should handle untagged jobs'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'A list of runner tags'
          optional :maximum_timeout, type: Integer,
            desc: 'Maximum timeout that limits the amount of time (in seconds) ' \
                  'that runners can run jobs'
          mutually_exclusive :maintainer_note, :maintenance_note
          mutually_exclusive :active, :paused
        end
        route_setting :authorization, skip_granular_token_authorization: :runner_token_auth
        post '/', urgency: :low, feature_category: :runner_core do
          attributes = attributes_for_keys(%i[description maintainer_note maintenance_note active paused locked run_untagged tag_list access_level maximum_timeout])
            .merge(attributes_for_keys(%w[name], params['info']))

          # Pull in deprecated maintainer_note if that's the only note value available
          deprecated_note = attributes.delete(:maintainer_note)
          attributes[:maintenance_note] ||= deprecated_note if deprecated_note
          attributes[:active] = !attributes.delete(:paused) if attributes.include?(:paused)

          result = ::Ci::Runners::RegisterRunnerService.new(params[:token], attributes).execute

          if result.error?
            case result.reason
            when :runner_registration_disallowed
              render_api_error_with_reason!(410, '410 Gone', result.message)
            else
              forbidden!(result.message)
            end
          end

          @runner = result.payload[:runner]
          if @runner.persisted?
            present @runner, with: Entities::Ci::RunnerRegistrationDetails
          else
            render_validation_error!(@runner)
          end
        end

        desc 'Delete a registered runner' do
          detail 'Deletes a specified registered runner.'
          summary "Delete a runner by authentication token"
          success code: 204, message: 'Resource deleted'
          failure [[403, 'Forbidden']]
          tags ['ci_runners']
        end
        params do
          requires :token, type: String, desc: "The runner's authentication token"
        end
        route_setting :authorization, skip_granular_token_authorization: :runner_token_auth
        delete '/', urgency: :low, feature_category: :runner_core do
          authenticate_runner!(ensure_runner_manager: false)

          destroy_conditionally!(current_runner) do
            ::Ci::Runners::UnregisterRunnerService.new(current_runner, params[:token]).execute
          end
        end

        desc 'Delete a registered runner manager' do
          summary 'Internal endpoint that deletes a runner manager by authentication token and system ID.'
          success code: 204, message: 'Runner manager was deleted'
          failure [[400, 'Bad Request'], [403, 'Forbidden'], [404, 'Not Found']]
          tags ['ci_runners']
        end
        params do
          requires :token, type: String, desc: "The runner's authentication token"
          requires :system_id, type: String, desc: "The runner's system identifier."
        end
        route_setting :authorization, skip_granular_token_authorization: :runner_token_auth
        delete '/managers', urgency: :low, feature_category: :fleet_visibility do
          authenticate_runner!(ensure_runner_manager: false)

          runner_manager = current_runner.runner_managers.find_by_system_xid(params[:system_id])
          not_found!('Runner manager not found') unless runner_manager

          destroy_conditionally!(runner_manager) do
            ::Ci::Runners::UnregisterRunnerManagerService.new(
              current_runner,
              params[:token],
              system_id: params[:system_id]
            ).execute
          end
        end

        desc 'Verify authentication for a registered runner' do
          detail 'Verifies authentication for a registered runner.'
          success code: 200, model: Entities::Ci::RunnerRegistrationDetails, message: 'Credentials are valid'
          failure [[403, 'Forbidden'], [422, 'Runner is orphaned']]
          tags ['ci_runners']
        end
        params do
          requires :token, type: String, desc: "The runner's authentication token"
          optional :system_id, type: String, desc: "The runner's system identifier"
        end
        route_setting :authorization, skip_granular_token_authorization: :runner_token_auth
        post '/verify', urgency: :low, feature_category: :runner_core do
          authenticate_runner!
          status 200

          present current_runner, with: Entities::Ci::RunnerRegistrationDetails
        end

        desc 'Reset a runner authentication token with the current token' do
          detail 'Resets a runner authentication token with the token used to authenticate the request.'
          success Entities::Ci::ResetTokenResult
          failure [[403, 'Forbidden'], [422, 'Unprocessable Entity']]
          tags ['ci_runners']
        end
        params do
          requires :token, type: String, desc: 'The current authentication token of the runner'
        end
        route_setting :authorization, skip_granular_token_authorization: :runner_token_auth
        post '/reset_authentication_token', urgency: :low, feature_category: :runner_core do
          authenticate_runner!

          result = ::Ci::Runners::ResetAuthenticationTokenService.new(runner: current_runner, source: :runner_api).execute
          error!(result.message, result.reason) if result.error?

          present current_runner.token_with_expiration, with: Entities::Ci::ResetTokenResult
        end

        resource :router do
          before do
            authenticate_runner_from_header!
            Gitlab::ApplicationContext.push(runner: current_runner_from_header)
          end

          desc 'Discover Job Router information' do
            detail 'Discovers Job Router information for a runner. You must provide a valid runner ' \
              'authentication token.'
            success Entities::Ci::JobRouter::DiscoveryInformation
            failure [
              { code: 403, message: '403 Forbidden' },
              { code: 501, message: '501 Not Implemented' }
            ]
            tags ['ci_runners']
          end
          route_setting :authorization, skip_granular_token_authorization: :runner_token_auth
          get '/discovery', urgency: :low, feature_category: :runner_core do
            unless Gitlab::Kas.enabled? && job_router_enabled?(current_runner_from_header)
              render_api_error!('Job Router is not available. Please contact your administrator.', 501)
            end

            present({
              server_url: Gitlab::Kas.external_url
            }, with: Entities::Ci::JobRouter::DiscoveryInformation)
          end
        end
      end

      resource :jobs do
        helpers ::API::Helpers::RateLimiter
        helpers ::API::Ci::Helpers::JobRequest

        before { set_application_context }

        desc 'Request a job' do
          success [
            { code: 201, model: Entities::Ci::JobRequest::Response, message: 'Job was scheduled' },
            { code: 204, message: 'No job for Runner' }
          ]
          failure [[403, 'Forbidden'],
            [409, 'Conflict'],
            [422, 'Runner is orphaned'],
            [429, 'Too Many Requests']]
          tags ['jobs']
        end
        params do
          use :request_job_params
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

        route_setting :authorization, skip_granular_token_authorization: :runner_token_auth
        post '/request', urgency: :low, feature_category: :continuous_integration do
          check_rate_limit!(:runner_jobs_request_api, scope: [Gitlab::CryptoHelper.sha256(params[:token])], user: nil)

          authenticate_runner!(creation_state: :finished)

          result = acquire_ci_job!(declared_params(include_missing: false))

          env['api.format'] = :build_json
          body result.build_json
        end

        desc 'Update a job' do
          success [
            { code: 200, message: 'Job was updated' },
            { code: 202, message: 'Update accepted' }
          ]
          failure [[400, 'Unknown parameters'],
            [403, 'Forbidden'],
            [409, 'Conflict'],
            [429, 'Too Many Requests']]
          tags ['jobs']
        end
        params do
          requires :token, type: String, desc: "Job's authentication token"
          requires :id, type: Integer, desc: "Job's ID"
          optional :state, type: String, desc: "Job's status: running, success, failed"
          optional :checksum, type: String, desc: "Job's trace CRC32 checksum"
          optional :failure_reason, type: String, desc: "Job's failure_reason"
          optional :output, type: Hash, desc: 'Build log state' do
            optional :checksum, type: String, desc: "Job's trace CRC32 checksum"
            optional :bytesize, type: Integer, desc: "Job's trace size in bytes"
          end
          optional :exit_code, type: Integer, desc: "Job's exit code"
        end
        route_setting :authorization, skip_granular_token_authorization: :job_token_auth
        put '/:id', urgency: :low, feature_category: :continuous_integration do
          check_rate_limit!(:runner_jobs_api, scope: [Gitlab::CryptoHelper.sha256(job_token)], user: nil)

          job = authenticate_job!(heartbeat_runner: true, fail_on_expired_token: true)

          Gitlab::Metrics.add_event(:update_build)

          service = ::Ci::UpdateBuildStateService.new(job, declared_params(include_missing: false))

          service.execute.then do |result|
            track_ci_minutes_usage!(job)

            header 'Job-Status', job.status
            header 'X-GitLab-Trace-Update-Interval', result.backoff
            status result.status
            body result.status.to_s
          end
        end

        desc 'Append a patch to the job trace' do
          success code: 202, message: 'Trace was patched'
          failure [[400, 'Missing Content-Range header'],
            [403, 'Forbidden'],
            [416, 'Range not satisfiable'],
            [429, 'Too Many Requests']]
          tags ['jobs']
        end
        params do
          requires :id, type: Integer, desc: "Job's ID"
          optional :token, type: String, desc: "Job's authentication token" # token can also be present in header
          optional :debug_trace, type: Boolean, desc: 'Enable or disable the debug trace'
        end
        route_setting :authorization, skip_granular_token_authorization: :job_token_auth
        patch '/:id/trace', urgency: :low, feature_category: :continuous_integration do
          check_rate_limit!(:runner_jobs_patch_trace_api, scope: [Gitlab::CryptoHelper.sha256(job_token)], user: nil)

          job = authenticate_job!(heartbeat_runner: true, fail_on_expired_token: true)

          error!('400 Missing header Content-Range', 400) unless request.headers.key?('Content-Range')
          content_range = request.headers['Content-Range']
          debug_trace = Gitlab::Utils.to_boolean(params[:debug_trace])

          result = ::Ci::AppendBuildTraceService
            .new(job, content_range: content_range, debug_trace: debug_trace)
            .execute(request.body.read)

          if result.status == 403
            break error!('403 Forbidden', 403)
          end

          if result.status == 416
            break error!('416 Range Not Satisfiable', 416, { 'Range' => "0-#{result.stream_size}" })
          end

          track_ci_minutes_usage!(job)

          status result.status
          header 'Job-Status', job.status
          header 'Range', "0-#{result.stream_size}"
          header 'X-GitLab-Trace-Update-Interval', job.trace.update_interval.to_s
        end

        desc 'Authorize uploading job artifact' do
          success code: 200, message: 'Upload allowed'
          failure [[403, 'Forbidden'],
            [405, 'Artifacts support not enabled'],
            [413, 'File too large'],
            [429, 'Too Many Requests']]
          tags ['jobs']
        end
        params do
          requires :id, type: Integer, desc: "Job's ID"
          optional :token, type: String, desc: "Job's authentication token" # token can also be present in header

          # NOTE:
          # In current runner, filesize parameter would be empty here. This is because archive is streamed by runner,
          # so the archive size is not known ahead of time. Streaming is done to not use additional I/O on
          # Runner to first save, and then send via Network.
          optional :filesize, type: Integer, desc: 'Size of artifact file'

          optional :artifact_type, type: String, desc: 'The type of artifact',
            default: 'archive', values: ::Ci::JobArtifact.file_types.keys
        end
        route_setting :authorization, skip_granular_token_authorization: :job_token_auth
        post '/:id/artifacts/authorize', feature_category: :job_artifacts, urgency: :low do
          check_rate_limit!(:runner_jobs_api, scope: [Gitlab::CryptoHelper.sha256(job_token)], user: nil)

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

        desc 'Upload a job artifact' do
          success code: 201
          failure [[400, 'Bad request'],
            [403, 'Forbidden'],
            [405, 'Artifacts support not enabled'],
            [413, 'File too large'],
            [429, 'Too Many Requests']]
          tags ['jobs']
        end
        params do
          requires :id, type: Integer, desc: "Job's ID"
          requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: "The artifact file to store (generated by Multipart middleware)", documentation: { type: 'file' }
          optional :token, type: String, desc: "Job's authentication token" # token can also be present in header
          optional :expire_in, type: String, desc: 'Specify when artifact should expire'
          optional :artifact_type, type: String, desc: 'The type of artifact',
            default: 'archive', values: ::Ci::JobArtifact.file_types.keys
          optional :artifact_format, type: String, desc: 'The format of artifact',
            default: 'zip', values: ::Ci::JobArtifact.file_formats.keys
          optional :metadata, type: ::API::Validations::Types::WorkhorseFile, desc: 'The artifact metadata to store (generated by Multipart middleware)', documentation: { type: 'file' }
          optional :accessibility, type: String, desc: 'Specify accessibility level of artifact private/public'
        end
        route_setting :authorization, skip_granular_token_authorization: :job_token_auth
        post '/:id/artifacts', feature_category: :job_artifacts, urgency: :low do
          check_rate_limit!(:runner_jobs_api, scope: [Gitlab::CryptoHelper.sha256(job_token)], user: nil)

          not_allowed! unless Gitlab.config.artifacts.enabled
          require_gitlab_workhorse!

          job = authenticate_job!

          artifacts = params[:file]
          metadata = params[:metadata]

          result = ::Ci::JobArtifacts::CreateService.new(job).execute(artifacts, params, metadata_file: metadata)

          if result[:status] == :success
            log_artifacts_filesize(result[:artifact])

            status :created
            body "201"
          else
            render_api_error!(result[:message], result[:http_status])
          end
        end

        desc 'Download the artifacts file for job' do
          success [
            { code: 200, message: 'Download allowed' },
            { code: 302, message: 'Found' }
          ]
          failure [[401, 'Unauthorized'],
            [403, 'Forbidden'],
            [404, 'Artifact not found'],
            [429, 'Too Many Requests']]
          tags ['jobs']
        end
        params do
          requires :id, type: Integer, desc: "Job's ID"
          optional :token, type: String, desc: "Job's authentication token" # token can also be present in header
          optional :direct_download, default: false, type: Boolean, desc: 'Perform direct download from remote storage instead of proxying artifacts'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs,
          allow_public_access_for_enabled_project_features: [:repository, :builds],
          skip_granular_token_authorization: :job_token_auth
        get '/:id/artifacts', feature_category: :job_artifacts do
          check_rate_limit!(:runner_jobs_api, scope: [Gitlab::CryptoHelper.sha256(job_token)], user: nil)

          authenticate_job_via_dependent_job!
          authorize_job_token_policies!(current_job.project)

          not_found! unless current_job.artifacts_file&.exists?

          audit_download(current_job, current_job.artifacts_file.filename)
          present_artifacts_file!(current_job.artifacts_file, supports_direct_download: params[:direct_download])
        end
      end
    end
  end
end
