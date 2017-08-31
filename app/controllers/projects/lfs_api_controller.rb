class Projects::LfsApiController < Projects::GitHttpClientController
  include ApplicationSettingsHelper
  include ApplicationHelper
  include GitlabRoutingHelper
  include LfsRequest

  skip_before_action :lfs_check_access!, only: [:deprecated]
  before_action :lfs_check_batch_operation!, only: [:batch]

  def batch
    unless objects.present?
      render_lfs_not_found
      return
    end

    if download_request?
      render json: { objects: download_objects! }
    elsif upload_request?
      render json: { objects: upload_objects! }
    else
      raise "Never reached"
    end
  end

  def deprecated
    render(
      json: {
        message: 'Server supports batch API only, please update your Git LFS client to version 1.0.1 and up.',
        documentation_url: "#{Gitlab.config.gitlab.url}/help"
      },
      status: 501
    )
  end

  private

  def download_request?
    params[:operation] == 'download'
  end

  def upload_request?
    params[:operation] == 'upload'
  end

  def existing_oids
    @existing_oids ||= begin
      storage_project.lfs_objects.where(oid: objects.map { |o| o['oid'].to_s }).pluck(:oid)
    end
  end

  def download_objects!
    objects.each do |object|
      if existing_oids.include?(object[:oid])
        object[:actions] = download_actions(object)

        if Guest.can?(:download_code, project)
          object[:authenticated] = true
        end
      else
        object[:error] = {
          code: 404,
          message: "Object does not exist on the server or you don't have permissions to access it"
        }
      end
    end
    objects
  end

  def upload_objects!
    objects.each do |object|
      object[:actions] = upload_actions(object) unless existing_oids.include?(object[:oid])
    end
    objects
  end

  def download_actions(object)
    {
      download: {
        href: "#{project.http_url_to_repo}/gitlab-lfs/objects/#{object[:oid]}",
        header: {
          Authorization: request.headers['Authorization']
        }.compact
      }
    }
  end

  def upload_actions(object)
    {
      upload: {
        href: "#{project.http_url_to_repo}/gitlab-lfs/objects/#{object[:oid]}/#{object[:size]}",
        header: {
          Authorization: request.headers['Authorization']
        }.compact
      }
    }
  end

  def lfs_check_batch_operation!
    if upload_request? && Gitlab::Geo.secondary?
      render(
        json: {
          message: "You cannot write to a secondary GitLab Geo instance. Please use #{geo_primary_default_url_to_repo(project)} instead."
        },
        content_type: "application/vnd.git-lfs+json",
        status: 403
      )
    end
  end
end
