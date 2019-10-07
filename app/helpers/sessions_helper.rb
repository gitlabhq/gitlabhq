# frozen_string_literal: true

module SessionsHelper
  def unconfirmed_email?
    flash[:alert] == t(:unconfirmed, scope: [:devise, :failure])
  end

  def use_experimental_separate_sign_up_flow?
    ::Gitlab.dev_env_or_com? && Feature.enabled?(:experimental_separate_sign_up_flow)
  end
end
