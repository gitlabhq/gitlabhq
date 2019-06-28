# frozen_string_literal: true

module ContinueParams
  include InternalRedirect
  extend ActiveSupport::Concern

  def continue_params
    continue_params = params[:continue]
    return {} unless continue_params

    continue_params = continue_params.permit(:to, :notice, :notice_now)
    continue_params[:to] = safe_redirect_path(continue_params[:to])

    continue_params
  end
end
