# frozen_string_literal: true

module Deployments
  class DeploymentPresenter < Gitlab::View::Presenter::Delegated
    presents ::Deployment, as: :deployment
  end
end
