module API
  module V3
    class Builds < Grape::API
      include PaginationParams

      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        helpers do
          params :optional_scope do
            optional :scope, types: [String, Array[String]], desc: 'The scope of builds to show',
                             values:  %w(pending running failed success canceled skipped),
                             coerce_with: ->(scope) {
                                            if scope.is_a?(String)
                                              [scope]
                                            elsif   scope.is_a?(::Hash)
                                              scope.values
                                            else
                                              ['unknown']
                                            end
                                          }
          end
        end

        desc 'Get a project builds' do
          success ::API::V3::Entities::Build
        end
        params do
          use :optional_scope
          use :pagination
        end
        get ':id/builds' do
          builds = user_project.builds.order('id DESC')
          builds = filter_builds(builds, params[:scope])

          builds = builds.preload(:user, :job_artifacts_archive, :runner, pipeline: :project)
          present paginate(builds), with: ::API::V3::Entities::Build
        end

        desc 'Get builds for a specific commit of a project' do
          success ::API::V3::Entities::Build
        end
        params do
          requires :sha, type: String, desc: 'The SHA id of a commit'
          use :optional_scope
          use :pagination
        end
        get ':id/repository/commits/:sha/builds' do
          authorize_read_builds!

          break not_found! unless user_project.commit(params[:sha])

          pipelines = user_project.pipelines.where(sha: params[:sha])
          builds = user_project.builds.where(pipeline: pipelines).order('id DESC')
          builds = filter_builds(builds, params[:scope])

          present paginate(builds), with: ::API::V3::Entities::Build
        end

        desc 'Get a specific build of a project' do
          success ::API::V3::Entities::Build
        end
        params do
          requires :build_id, type: Integer, desc: 'The ID of a build'
        end
        get ':id/builds/:build_id' do
          authorize_read_builds!

          build = get_build!(params[:build_id])

          present build, with: ::API::V3::Entities::Build
        end

        desc 'Download the artifacts file from build' do
          detail 'This feature was introduced in GitLab 8.5'
        end
        params do
          requires :build_id, type: Integer, desc: 'The ID of a build'
        end
        get ':id/builds/:build_id/artifacts' do
          authorize_read_builds!

          build = get_build!(params[:build_id])

          present_carrierwave_file!(build.artifacts_file)
        end

        desc 'Download the artifacts file from build' do
          detail 'This feature was introduced in GitLab 8.10'
        end
        params do
          requires :ref_name, type: String, desc: 'The ref from repository'
          requires :job,      type: String, desc: 'The name for the build'
        end
        get ':id/builds/artifacts/:ref_name/download',
          requirements: { ref_name: /.+/ } do
          authorize_read_builds!

          builds = user_project.latest_successful_builds_for(params[:ref_name])
          latest_build = builds.find_by!(name: params[:job])

          present_carrierwave_file!(latest_build.artifacts_file)
        end

        # TODO: We should use `present_disk_file!` and leave this implementation for backward compatibility (when build trace
        #       is saved in the DB instead of file). But before that, we need to consider how to replace the value of
        #       `runners_token` with some mask (like `xxxxxx`) when sending trace file directly by workhorse.
        desc 'Get a trace of a specific build of a project'
        params do
          requires :build_id, type: Integer, desc: 'The ID of a build'
        end
        get ':id/builds/:build_id/trace' do
          authorize_read_builds!

          build = get_build!(params[:build_id])

          header 'Content-Disposition', "infile; filename=\"#{build.id}.log\""
          content_type 'text/plain'
          env['api.format'] = :binary

          trace = build.trace.raw
          body trace
        end

        desc 'Cancel a specific build of a project' do
          success ::API::V3::Entities::Build
        end
        params do
          requires :build_id, type: Integer, desc: 'The ID of a build'
        end
        post ':id/builds/:build_id/cancel' do
          authorize_update_builds!

          build = get_build!(params[:build_id])
          authorize!(:update_build, build)

          build.cancel

          present build, with: ::API::V3::Entities::Build
        end

        desc 'Retry a specific build of a project' do
          success ::API::V3::Entities::Build
        end
        params do
          requires :build_id, type: Integer, desc: 'The ID of a build'
        end
        post ':id/builds/:build_id/retry' do
          authorize_update_builds!

          build = get_build!(params[:build_id])
          authorize!(:update_build, build)
          break forbidden!('Build is not retryable') unless build.retryable?

          build = Ci::Build.retry(build, current_user)

          present build, with: ::API::V3::Entities::Build
        end

        desc 'Erase build (remove artifacts and build trace)' do
          success ::API::V3::Entities::Build
        end
        params do
          requires :build_id, type: Integer, desc: 'The ID of a build'
        end
        post ':id/builds/:build_id/erase' do
          authorize_update_builds!

          build = get_build!(params[:build_id])
          authorize!(:erase_build, build)
          break forbidden!('Build is not erasable!') unless build.erasable?

          build.erase(erased_by: current_user)
          present build, with: ::API::V3::Entities::Build
        end

        desc 'Keep the artifacts to prevent them from being deleted' do
          success ::API::V3::Entities::Build
        end
        params do
          requires :build_id, type: Integer, desc: 'The ID of a build'
        end
        post ':id/builds/:build_id/artifacts/keep' do
          authorize_update_builds!

          build = get_build!(params[:build_id])
          authorize!(:update_build, build)
          break not_found!(build) unless build.artifacts?

          build.keep_artifacts!

          status 200
          present build, with: ::API::V3::Entities::Build
        end

        desc 'Trigger a manual build' do
          success ::API::V3::Entities::Build
          detail 'This feature was added in GitLab 8.11'
        end
        params do
          requires :build_id, type: Integer, desc: 'The ID of a Build'
        end
        post ":id/builds/:build_id/play" do
          authorize_read_builds!

          build = get_build!(params[:build_id])
          authorize!(:update_build, build)
          bad_request!("Unplayable Job") unless build.playable?

          build.play(current_user)

          status 200
          present build, with: ::API::V3::Entities::Build
        end
      end

      helpers do
        def find_build(id)
          user_project.builds.find_by(id: id.to_i)
        end

        def get_build!(id)
          find_build(id) || not_found!
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
end
