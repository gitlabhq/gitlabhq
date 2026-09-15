# frozen_string_literal: true

module ContinueParams
  include InternalRedirect
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  def continue_params
    return {} unless continue_param

    continue_param.merge(to: safe_redirect_path(continue_param[:to]))
  end

  private

  def continue_param
    params.permit(continue: [:to, :notice, :notice_now])[:continue]
  end
  strong_memoize_attr :continue_param
end
