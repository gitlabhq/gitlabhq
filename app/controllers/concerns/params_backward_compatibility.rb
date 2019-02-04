# frozen_string_literal: true

module ParamsBackwardCompatibility
  private

  def set_non_archived_param
    params[:non_archived] = params[:archived].blank?
  end
end
