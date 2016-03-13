module ContinueParams
  extend ActiveSupport::Concern

  def continue_params
    continue_params = params[:continue]
    return nil unless continue_params

    continue_params = continue_params.permit(:to, :notice, :notice_now)
    return unless continue_params[:to] && continue_params[:to].start_with?('/')

    continue_params
  end
end
