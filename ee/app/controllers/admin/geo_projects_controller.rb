# frozen_string_literal: true

class Admin::GeoProjectsController < Admin::ApplicationController
  before_action :check_license
  before_action :load_registry, except: [:index]

  helper ::EE::GeoHelper

  def index
    finder = ::Geo::ProjectRegistryStatusFinder.new

    case params[:sync_status]
    when 'never'
      @projects = finder.never_synced_projects.page(params[:page])
    when 'failed'
      @registries = finder.failed_projects.page(params[:page])
    when 'pending'
      @registries = finder.pending_projects.page(params[:page])
    else
      @registries = finder.synced_projects.page(params[:page])
    end
  end

  def recheck
    @registry.flag_repository_for_recheck!

    redirect_back_or_admin_geo_projects(notice: "#{@registry.project.full_name} is scheduled for recheck")
  end

  def resync
    @registry.flag_repository_for_resync!

    redirect_back_or_admin_geo_projects(notice: "#{@registry.project.full_name} is scheduled for resync")
  end

  def force_redownload
    @registry.flag_repository_for_redownload!

    redirect_back_or_admin_geo_projects(notice: "#{@registry.project.full_name} is scheduled for forced re-download")
  end

  private

  def check_license
    unless Gitlab::Geo.license_allows?
      redirect_to admin_license_path, alert: 'You need a different license to use Geo replication'
    end
  end

  def load_registry
    @registry = ::Geo::ProjectRegistry.find_by_id(params[:id])
  end

  def redirect_back_or_admin_geo_projects(params)
    redirect_back_or_default(default: admin_geo_projects_path, options: params)
  end
end
