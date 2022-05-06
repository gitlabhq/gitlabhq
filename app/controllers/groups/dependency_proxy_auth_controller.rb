# frozen_string_literal: true

class Groups::DependencyProxyAuthController < ::Groups::DependencyProxy::ApplicationController
  feature_category :dependency_proxy
  urgency :low

  def authenticate
    render plain: '', status: :ok
  end
end
