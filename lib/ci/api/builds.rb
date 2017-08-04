module Ci
  module API
    class Builds < Grape::API
      resource :builds do
        desc 'Register a runner' do
          detail 'Runners only'
        end
        params do
          requires :token, type: String, desc: 'The build authorization token'
        end
        post "register" do
          authenticate_runner!

          not_found! unless current_runner.active?
          update_runner_info

          if current_runner.is_runner_queue_value_latest?(params[:last_update])
            header 'X-GitLab-Last-Update', params[:last_update]
            Gitlab::Metrics.add_event(:build_not_found_cached)
            return build_not_found!
          end

          new_update = current_runner.ensure_runner_queue_value

          result = Ci::RegisterJobService.new(current_runner).execute

          if result.valid?
            if result.build
              Gitlab::Metrics.add_event(:build_found,
                                        project: result.build.project.full_path)

              present result.build, with: Entities::BuildDetails
            else
              Gitlab::Metrics.add_event(:build_not_found)

              header 'X-GitLab-Last-Update', new_update

              build_not_found!
            end
          else
            # We received build that is invalid due to concurrency conflict
            Gitlab::Metrics.add_event(:build_invalid)
            conflict!
          end
        end

        desc 'Update an existing build' do
          detail 'Runners only'
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a build'
          optional :state, type: String, values: ['success', 'failed'], desc: 'The state of a build'
          optional :trace, type: String, desc: 'The trace of a build'
        end
        put ":id" do
          authenticate_runner!
          build = Ci::Build.where(runner_id: current_runner.id).running.find(params[:id])
          validate_build!(build)

          update_runner_info

          build.trace.set(params[:trace]) if params[:trace]

          Gitlab::Metrics.add_event(:update_build,
                                    project: build.project.full_path)
          case params[:state]
          when 'success'
            build.success
          when 'failed'
            build.drop
          end
        end

        desc 'Send incremental log update' do
          detail 'Runners only'
          headers 'Content-Range' => {
                    description: 'Range of content that was sent',
                    required: true
                  },
                  'HTTP_BUILD_TOKEN' => {
                    description: 'The build authorization token',
                    required: false
                  }
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a build'
          optional :token, type: String, desc: 'The build authorization token'
        end
        patch ":id/trace.txt" do
          build = authenticate_build!

          error!('400 Missing header Content-Range', 400) unless request.headers.key?('Content-Range')
          content_range = request.headers['Content-Range']
          content_range = content_range.split('-')

          stream_size = build.trace.append(request.body.read, content_range[0].to_i)
          if stream_size < 0
            return error!('416 Range Not Satisfiable', 416, { 'Range' => "0-#{-stream_size}" })
          end

          status 202
          header 'Build-Status', build.status
          header 'Range', "0-#{stream_size}"
        end

        desc 'Authorize artifacts uploading for a build' do
          detail 'Runners only'
          headers 'HTTP_BUILD_TOKEN' => {
                    description: 'The build authorization token',
                    required: false
                  }
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a build'
          optional :token, type: String, desc: 'The build authorization token'
          optional :filesize, type: Integer, desc: 'The size of the uploaded file'
        end
        post ":id/artifacts/authorize" do
          require_gitlab_workhorse!
          Gitlab::Workhorse.verify_api_request!(headers)
          not_allowed! unless Gitlab.config.artifacts.enabled
          build = authenticate_build!
          forbidden!('build is not running') unless build.running?

          if params[:filesize]
            file_size = params[:filesize]
            file_to_large! unless file_size < max_artifacts_size
          end

          status 200
          content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
          Gitlab::Workhorse.artifact_upload_ok
        end

        desc 'Upload artifacts to build' do
          detail 'Runners only'
          headers 'HTTP_BUILD_TOKEN' => {
                    description: 'The build authorization token',
                    required: false
                  }
          success Entities::BuildDetails
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a build'
          optional :token, type: String, desc: 'The build authorization token'
          #requires 'file.path', type: String, desc: 'Artifacts file'
          #requires 'file.name', type: String, desc: 'Artifacts file'
          optional :expire_in, type: String,
                   default: Gitlab::CurrentSettings.current_application_settings.default_artifacts_expire_in,
                   desc: 'Specify when artifacts should expire (ex. 7d)'
        end
        post ":id/artifacts" do
          require_gitlab_workhorse!
          not_allowed! unless Gitlab.config.artifacts.enabled
          build = authenticate_build!
          forbidden!('Build is not running!') unless build.running?

          pp params

          artifacts_upload_path = ArtifactUploader.artifacts_upload_path
          artifacts = uploaded_file(:file, artifacts_upload_path)
          metadata = uploaded_file(:metadata, artifacts_upload_path)

          bad_request!('Missing artifacts file!') unless artifacts
          file_to_large! unless artifacts.size < max_artifacts_size

          build.artifacts_file = artifacts
          build.artifacts_metadata = metadata
          build.artifacts_expire_in = params['expire_in']



          if build.save
            present(build, with: Entities::BuildDetails)
          else
            render_validation_error!(build)
          end
        end

        desc 'Download the artifacts file from build' do
          detail 'Runners only'
          headers 'HTTP_BUILD_TOKEN' => {
                    description: 'The build authorization token',
                    required: false
                  }
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a build'
          optional :token, type: String, desc: 'The build authorization token'
        end
        get ":id/artifacts" do
          build = authenticate_build!
          artifacts_file = build.artifacts_file

          not_found! unless artifacts_file.exists?

          if artifacts_file.file_storage?
            present_file!(artifacts_file.path, artifacts_file.filename)
          else
            redirect_to build.artifacts_file.url
          end
        end

        desc 'Remove the artifacts file from build' do
          detail 'Runners only'
          headers 'HTTP_BUILD_TOKEN' => {
                    description: 'The build authorization token',
                    required: false
                  }
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a build'
          optional :token, type: String, desc: 'The build authorization token'
        end
        delete ":id/artifacts" do
          build = authenticate_build!

          status(200)
          build.erase_artifacts!
        end
      end
    end
  end
end
