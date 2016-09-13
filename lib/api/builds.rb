module API
  # Projects builds API
  class Builds < Grape::API
    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects do

      desc 'Get a project builds' do
        success Entities::Build
        named "Get project pipeline builds"
      end
      params do
        optional :scope, type: String, desc: 'Scope filter; zero or more of: pending, running, failed, success, or canceled'
      end
      get ':id/builds' do
        builds = user_project.builds.order('id DESC')
        builds = filter_builds(builds, params[:scope])

        present paginate(builds), with: Entities::Build,
                                  user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Get builds for a specific commit of a project' do
        success Entities::Build
        named "Get a build for a given commit SHA"
      end
      params do
        requires :sha, type: String, desc: 'The SHA id of a commit'
        optional :scope, type: String, desc: 'Scope filter; zero or more of: pending, running, failed, success, or canceled'
      end
      get ':id/repository/commits/:sha/builds' do
        authorize_read_builds!

        return not_found! unless user_project.commit(params[:sha])

        pipelines = user_project.pipelines.where(sha: params[:sha])
        builds = user_project.builds.where(pipeline: pipelines).order('id DESC')
        builds = filter_builds(builds, params[:scope])

        present paginate(builds), with: Entities::Build,
                                  user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Get a specific build of a project' do
        success Entities::Build
        named 'Get a build by its ID'
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of a build'
      end
      get ':id/builds/:build_id' do
        authorize_read_builds!

        build = get_build!(params[:build_id])

        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Download the artifacts file from build' do
        success 200
        named 'Get the builds artifacts'
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of the build'
        requires :token, type: String, desc: 'The build authorization token'
      end
      get ':id/builds/:build_id/artifacts' do
        authorize_read_builds!

        build = get_build!(params[:build_id])

        present_artifacts!(build.artifacts_file)
      end

      desc 'Download the artifacts file for a ref_name and job' do
        success 200
      end
      params do
        requires :ref_name, type: String, regex: /.+/, desc: 'The ref from repository'
        requires :job, type: String, desc: 'The name for the build'
      end
      get ':id/builds/artifacts/:ref_name/download' do
        authorize_read_builds!

        builds = user_project.latest_successful_builds_for(params[:ref_name])
        latest_build = builds.find_by!(name: params[:job])

        present_artifacts!(latest_build.artifacts_file)
      end

      # TODO: We should use `present_file!` and leave this implementation for backward compatibility (when build trace
      #       is saved in the DB instead of file). But before that, we need to consider how to replace the value of
      #       `runners_token` with some mask (like `xxxxxx`) when sending trace file directly by workhorse.
      desc 'Get a trace of a specific build of a project' do
        success 200
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of the build'
      end
      get ':id/builds/:build_id/trace' do
        authorize_read_builds!

        build = get_build!(params[:build_id])

        header 'Content-Disposition', "infile; filename=\"#{build.id}.log\""
        content_type 'text/plain'
        env['api.format'] = :binary

        trace = build.trace
        body trace
      end

      desc 'Cancel a specific build of a project' do
        success Entities::Build
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of the build'
      end
      post ':id/builds/:build_id/cancel' do
        authorize_update_builds!

        build = get_build!(params[:build_id])

        build.cancel

        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Retry a specific build of a project' do
        success Entities::Build
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of the build'
      end
      post ':id/builds/:build_id/retry' do
        authorize_update_builds!

        build = get_build!(params[:build_id])
        return forbidden!('Build is not retryable') unless build.retryable?

        build = Ci::Build.retry(build, current_user)

        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Erase the build trace' do
        success Entities::Build
        named 'Remove artifacts and build trace for a build'
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of the build'
      end
      post ':id/builds/:build_id/erase' do
        authorize_update_builds!

        build = get_build!(params[:build_id])
        return forbidden!('Build is not erasable!') unless build.erasable?

        build.erase(erased_by: current_user)
        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :download_build_artifacts, user_project)
      end

      desc 'Keep the artifacts to prevent them from being deleted' do
        success Entities::Build
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of the build'
      end
      post ':id/builds/:build_id/artifacts/keep' do
        authorize_update_builds!

        build = get_build!(params[:build_id])
        return not_found!(build) unless build.artifacts?

        build.keep_artifacts!

        status 200
        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :read_build, user_project)
      end

      desc 'Trigger a manual build' do
        success Entities::Build
        detail 'This feature was added in GitLab 8.11'
      end
      params do
        requires :build_id, type: Integer, desc: 'The ID of a Build'
      end
      post ":id/builds/:build_id/play" do
        authorize_read_builds!

        build = get_build!(params[:build_id])

        bad_request!("Unplayable Build") unless build.playable?

        build.play(current_user)

        status 200
        present build, with: Entities::Build,
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
        scope =
          if scope.is_a?(String)
            [scope]
          elsif scope.is_a?(Hashie::Mash)
            scope.values
          else
            ['unknown']
          end

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
