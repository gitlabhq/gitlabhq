# frozen_string_literal: true
class Groups::Security::VulnerabilitiesController < Groups::ApplicationController
  before_action :ensure_security_dashboard_feature_enabled
  before_action :authorize_read_group_security_dashboard!

  def index
    @vulnerabilities = group.all_vulnerabilities.ordered
      .page(params[:page])
      .per(10)
      .to_a

    ::Gitlab::Vulnerabilities::OccurrencesPreloader.new.preload(@vulnerabilities) # rubocop:disable CodeReuse/ActiveRecord

    respond_to do |format|
      format.json do
        render json: Vulnerabilities::OccurrenceSerializer
          .new(current_user: @current_user)
          .with_pagination(request, response)
          .represent(@vulnerabilities)
      end
    end
  end

  def summary
    respond_to do |format|
      format.json do
        render json: VulnerabilitySummarySerializer.new.represent(group)
      end
    end
  end

  private

  def ensure_security_dashboard_feature_enabled
    render_404 unless @group.feature_available?(:security_dashboard)
  end

  def authorize_read_group_security_dashboard!
    render_403 unless can?(current_user, :read_group_security_dashboard, group)
  end
end
