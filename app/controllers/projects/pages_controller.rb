class Projects::PagesController < Projects::ApplicationController
  layout 'project_settings'

  before_action :authorize_update_pages!, except: [:show]
  before_action :authorize_remove_pages!, only: [:remove_pages]
  before_action :label, only: [:destroy]
  before_action :domain, only: [:show]

  helper_method :valid_certificate?, :valid_certificate_key?
  helper_method :valid_key_for_certificiate?, :valid_certificate_intermediates?
  helper_method :certificate, :certificate_key

  def index
    @domains = @project.pages_domains.order(:domain)
  end

  def show
  end

  def new
    @domain = @project.pages_domains.new
  end

  def create
    @domain = @project.pages_domains.create(pages_domain_params)

    if @domain.valid?
      redirect_to namespace_project_pages_path(@project.namespace, @project)
    else
      render 'new'
    end
  end

  def destroy
    @domain.destroy

    respond_to do |format|
      format.html do
        redirect_to(namespace_project_pages_path(@project.namespace, @project),
                    notice: 'Domain was removed')
      end
      format.js
    end
  end

  def remove_pages
    project.remove_pages
    project.pages_domains.destroy_all

    respond_to do |format|
      format.html  do
        redirect_to(namespace_project_pages_path(@project.namespace, @project),
                    notice: 'Pages were removed')
      end
    end
  end

  private

  def pages_domain_params
    params.require(:pages_domain).permit(
      :certificate,
      :key,
      :domain
    )
  end

  def domain
    @domain ||= @project.pages_domains.find_by(domain: params[:id].to_s)
  end
end
