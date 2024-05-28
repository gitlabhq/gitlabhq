# frozen_string_literal: true

class Groups::DependencyProxyAuthController < ::Groups::DependencyProxy::ApplicationController
  feature_category :virtual_registry
  urgency :low

  def authenticate
    render plain: '', status: :ok
  end
end
