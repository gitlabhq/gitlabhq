module LfsHelper
  def require_lfs_enabled!
    return if Gitlab.config.lfs.enabled

    render(
      json: {
        message: 'Git LFS is not enabled on this GitLab server, contact your admin.',
        documentation_url: "#{Gitlab.config.gitlab.url}/help",
      },
      status: 501
    )
  end

  def lfs_check_access!
    return if download_request? && lfs_download_access?
    return if upload_request? && lfs_upload_access?

    if project.public? || (user && user.can?(:read_project, project))
      render_lfs_forbidden
    else
      render_lfs_not_found
    end
  end

  def lfs_download_access?
    return false unless project.lfs_enabled?

    project.public? || ci? || lfs_deploy_key? || (user && user.can?(:download_code, project))
  end

  def lfs_upload_access?
    return false unless project.lfs_enabled?

    user && user.can?(:push_code, project)
  end

  def render_lfs_forbidden
    render(
      json: {
        message: 'Access forbidden. Check your access level.',
        documentation_url: "#{Gitlab.config.gitlab.url}/help",
      },
      content_type: "application/vnd.git-lfs+json",
      status: 403
    )
  end

  def render_lfs_not_found
    render(
      json: {
        message: 'Not found.',
        documentation_url: "#{Gitlab.config.gitlab.url}/help",
      },
      content_type: "application/vnd.git-lfs+json",
      status: 404
    )
  end

  def storage_project
    @storage_project ||= begin
      result = project

      loop do
        break unless result.forked?
        result = result.forked_from_project
      end

      result
    end
  end
end
