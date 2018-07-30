# frozen_string_literal: true

class Projects::ManagedLicensesController < Projects::ApplicationController
  before_action :software_license_policy, only: [:show, :edit, :update, :destroy]
  before_action :authorize_can_read!, only: [:index, :show]
  before_action :authorize_can_admin!, only: [:new, :create, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.json do
        render_software_license_policies
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render_software_license_policy
      end
    end
  end

  def new
    @software_license_policy = @project.software_license_policies.new
  end

  def create
    result = SoftwareLicensePolicies::CreateService.new(
      @project,
      current_user,
      software_license_policies_params
    ).execute

    if result[:status] == :success
      @software_license_policy = result[:software_license_policy]

      respond_to do |format|
        format.json { render_software_license_policy }
      end
    else
      respond_to do |format|
        format.json { render_error(result[:message], 400) }
      end
    end
  end

  def edit
  end

  def update
    result = SoftwareLicensePolicies::UpdateService.new(
      @project,
      current_user,
      software_license_policies_params
    ).execute(@software_license_policy)

    if result[:status] == :success
      respond_to do |format|
        format.json { render_software_license_policy }
      end
    else
      respond_to do |format|
        format.json { render_error(result[:message], 400) }
      end
    end
  end

  def destroy
    @software_license_policy.destroy!

    respond_to do |format|
      format.json { render_ok }
    end
  end

  private

  def respond_400
    head :bad_request
  end

  # Fetch the existing software license policy when given an id or name
  def software_license_policy
    id = params[:id]
    id = CGI.unescape(id) unless id.is_a?(Integer) || id =~ /^\d+$/
    @software_license_policy ||= SoftwareLicensePoliciesFinder.new(current_user, project).find_by_name_or_id(id)

    if @software_license_policy.nil?
      # The license was not found
      render_404
    end
  end

  def render_ok
    render status: :ok, nothing: true
  end

  def render_software_license_policy
    render status: :ok, json: ManagedLicenseSerializer.new.represent(@software_license_policy)
  end

  def render_software_license_policies
    render status: :ok, json: { software_license_policies: ManagedLicenseSerializer.new.represent(@project.software_license_policies) }
  end

  def render_error(error, status = 400)
    render json: error, status: status
  end

  def software_license_policies_params
    # Require the presence of an hash containing the software license policy fields
    params.require(:managed_license).permit(:name, :approval_status)
  end

  def authorize_can_read!
    render_404 unless can?(current_user, :read_software_license_policy, @project)
  end

  def authorize_can_admin!
    authorize_can_read!
    render_403 unless can?(current_user, :admin_software_license_policy, @project)
  end
end
