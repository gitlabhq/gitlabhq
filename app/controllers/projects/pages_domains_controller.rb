# frozen_string_literal: true

class Projects::PagesDomainsController < Projects::ApplicationController
  layout 'project_settings'

  before_action :require_pages_enabled!
  before_action :authorize_update_pages!
  before_action :domain, except: [:new, :create]

  helper_method :domain_presenter

  feature_category :pages

  def show
    return unless domain_presenter.needs_verification?

    flash.now[:warning] = _("This domain is not verified. You will need to verify ownership before access is enabled.")
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

    redirect_to project_pages_domain_path(@project, @domain)
  end

  def retry_auto_ssl
    ::Pages::Domains::RetryAcmeOrderService.new(@domain).execute

    redirect_to project_pages_domain_path(@project, @domain)
  end

  def edit
    redirect_to project_pages_domain_path(@project, @domain)
  end

  def create
    @domain = ::Pages::Domains::CreateService.new(@project, current_user, create_params).execute

    if @domain&.persisted?
      redirect_to project_pages_domain_path(@project, @domain)
    else
      render 'new'
    end
  end

  def update
    service = ::Pages::Domains::UpdateService.new(@project, current_user, update_params)

    if service.execute(@domain)
      redirect_to project_pages_path(@project),
        status: :found,
        notice: 'Domain was updated'
    else
      render 'show'
    end
  end

  def destroy
    ::Pages::Domains::DeleteService.new(@project, current_user).execute(@domain)

    respond_to do |format|
      format.html do
        redirect_to project_pages_path(@project), status: :found, notice: 'Domain was removed'
      end
      format.js
    end
  end

  def clean_certificate
    update_params = { user_provided_certificate: nil, user_provided_key: nil }
    service = ::Pages::Domains::UpdateService.new(@project, current_user, update_params)

    flash[:alert] = @domain.errors.full_messages.join(', ') unless service.execute(@domain)

    redirect_to project_pages_domain_path(@project, @domain)
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

  def domain_presenter
    @domain_presenter ||= domain.present(current_user: current_user)
  end
end
