module ArtifactHelper
  include GitlabRoutingHelper

  def link_to_artifact(project, job, file)
    if external_url?(file.blob)
      html_artifact_url(project, job, file.blob)
    else
      file_project_job_artifacts_path(project, job, path: file.path)
    end
  end

  def external_url?(blob)
    blob.name.end_with?(".html") &&
      pages_config.enabled &&
      pages_config.artifacts_server
  end

  private

  def html_artifact_url(project, job, blob)
    http = pages_config.https ? "https://" : "http://"
    domain = "#{project.namespace.to_param}.#{pages_config.host}/"
    path = "-/jobs/#{job.id}/artifacts/#{blob.path}"

    http + domain + path
  end

  def pages_config
    Gitlab.config.pages
  end
end
