# frozen_string_literal: true

class Admin::Serverless::DomainsController < Admin::ApplicationController
  before_action :check_feature_flag
  before_action :domain, only: [:update, :verify]

  def index
    @domain = PagesDomain.instance_serverless.first_or_initialize
  end

  def create
    if PagesDomain.instance_serverless.count > 0
      return redirect_to admin_serverless_domains_path, notice: _('An instance-level serverless domain already exists.')
    end

    @domain = PagesDomain.instance_serverless.create(create_params)

    if @domain.persisted?
      redirect_to admin_serverless_domains_path, notice: _('Domain was successfully created.')
    else
      render 'index'
    end
  end

  def update
    if domain.update(update_params)
      redirect_to admin_serverless_domains_path, notice: _('Domain was successfully updated.')
    else
      render 'index'
    end
  end

  def verify
    result = VerifyPagesDomainService.new(domain).execute

    if result[:status] == :success
      flash[:notice] = _('Successfully verified domain ownership')
    else
      flash[:alert] = _('Failed to verify domain ownership')
    end

    redirect_to admin_serverless_domains_path
  end

  private

  def domain
    @domain = PagesDomain.instance_serverless.find(params[:id])
  end

  def check_feature_flag
    render_404 unless Feature.enabled?(:serverless_domain)
  end

  def update_params
    params.require(:pages_domain).permit(:user_provided_certificate, :user_provided_key)
  end

  def create_params
    params.require(:pages_domain).permit(:domain, :user_provided_certificate, :user_provided_key)
  end
end
