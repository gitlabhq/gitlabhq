# frozen_string_literal: true

module Routing
  module ArtifactsHelper
    # Rails path generators are slow because they need to do large regex comparisons
    # against the arguments. We can speed this up 10x by generating the strings directly.

    # /*namespace_id/:project_id/-/jobs/:job_id/artifacts/download(.:format)
    def fast_download_project_job_artifacts_path(project, job, params = {})
      expose_fast_artifacts_path(project, job, :download, params)
    end

    # /*namespace_id/:project_id/-/jobs/:job_id/artifacts/keep(.:format)
    def fast_keep_project_job_artifacts_path(project, job)
      expose_fast_artifacts_path(project, job, :keep)
    end

    #  /*namespace_id/:project_id/-/jobs/:job_id/artifacts/browse(/*path)
    def fast_browse_project_job_artifacts_path(project, job)
      expose_fast_artifacts_path(project, job, :browse)
    end

    def expose_fast_artifacts_path(project, job, action, params = {})
      path = "#{project.full_path}/-/jobs/#{job.id}/artifacts/#{action}"

      unless params.empty?
        path += "?#{params.to_query}"
      end

      Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, path)
    end

    def artifacts_action_path(path, project, build)
      action, path_params = path.split('/', 2)
      args = [project, build, path_params]

      case action
      when 'download'
        download_project_job_artifacts_path(*args)
      when 'browse'
        browse_project_job_artifacts_path(*args)
      when 'file'
        file_project_job_artifacts_path(*args)
      when 'raw'
        raw_project_job_artifacts_path(*args)
      end
    end
  end
end
