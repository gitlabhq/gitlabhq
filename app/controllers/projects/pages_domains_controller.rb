# frozen_string_literal: true

class Projects::PagesDomainsController < Projects::ApplicationController
  layout 'project_settings'

  before_action :require_pages_enabled!
  before_action :authorize_update_pages!
  before_action :domain, except: [:new, :create]

  def show
    redirect_to edit_project_pages_domain_path(@project, @domain)
  end

  def new
    @domain = @project.pages_domains.new
  end

  def verify
    result = VerifyPagesDomainService.new(@domain).execute

    if result[:status] == :success
      flash[:notice] = 'Successfully verified domain ownership'
    else
      flash[:alert] = 'Failed to verify domain ownership'
    end

    redirect_to edit_project_pages_domain_path(@project, @domain)
  end

  def edit
  end

  def create
    @domain = @project.pages_domains.create(create_params)

    if @domain.valid?
      redirect_to edit_project_pages_domain_path(@project, @domain)
    else
      render 'new'
    end
  end

  def update
    if @domain.update(update_params)
      redirect_to project_pages_path(@project),
        status: :found,
        notice: 'Domain was updated'
    else
      render 'edit'
    end
  end

  def destroy
    @domain.destroy

    respond_to do |format|
      format.html do
        redirect_to project_pages_path(@project),
                    status: :found,
                    notice: 'Domain was removed'
      end
      format.js
    end
  end

  def clean_certificate
    unless @domain.update(user_provided_certificate: nil, user_provided_key: nil)
      flash[:alert] = @domain.errors.full_messages.join(', ')
    end

    redirect_to edit_project_pages_domain_path(@project, @domain)
  end

  private

  def create_params
    params.require(:pages_domain).permit(:user_provided_key, :user_provided_certificate, :domain, :auto_ssl_enabled)
  end

  def update_params
    params.fetch(:pages_domain, {}).permit(:user_provided_key, :user_provided_certificate, :auto_ssl_enabled)
  end

  def domain
    @domain ||= @project.pages_domains.find_by_domain!(params[:id].to_s)
  end
end
