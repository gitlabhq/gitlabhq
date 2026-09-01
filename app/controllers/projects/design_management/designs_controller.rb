# frozen_string_literal: true

class Projects::DesignManagement::DesignsController < Projects::ApplicationController
  # Allow design images to be fetched with token authentication (like
  # repository archives and release downloads): they have no API
  # equivalent, so API clients would otherwise have no way to render them
  # on private projects. Authorization is unchanged and still enforced by
  # `authorize_read_design!` below.
  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:design) }

  before_action :authorize_read_design!

  feature_category :design_management
  urgency :low

  private

  def authorize_read_design!
    access_denied! unless can?(current_user, :read_design, design)
  end

  def design_params
    params.permit(:design_id, :sha)
  end
  strong_memoize_attr :design_params

  def design
    @design ||= project.designs.find(design_params[:design_id])
  end

  def sha
    design_params[:sha].presence
  end
end
