# frozen_string_literal: true

class Groups::ImportsController < Groups::ApplicationController
  include ContinueParams

  feature_category :importers
  urgency :low

  before_action :ensure_group_in_current_organization!

  def show
    if @group.import_state.nil? || @group.import_state.finished?
      if continue_params[:to]
        redirect_to continue_params[:to], notice: continue_params[:notice]
      else
        redirect_to group_path(@group), notice: s_('GroupImport|The group was successfully imported.')
      end
    elsif @group.import_state.failed?
      redirect_to new_group_path(@group),
        alert: format(s_('GroupImport|Failed to import group: %{error}'), error: @group.import_state.last_error)
    else
      flash.now[:notice] = continue_params[:notice_now]
    end
  end

  private

  def ensure_group_in_current_organization!
    render_404 unless @group&.organization_id == Current.organization.id
  end
end
