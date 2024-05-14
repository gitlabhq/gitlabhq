# frozen_string_literal: true

class Projects::DesignManagement::DesignsController < Projects::ApplicationController
  before_action :authorize_read_design!

  feature_category :design_management
  urgency :low

  private

  def authorize_read_design!
    access_denied! unless can?(current_user, :read_design, design)
  end

  def design
    @design ||= project.designs.find(params[:design_id])
  end

  def sha
    params[:sha].presence
  end
end
