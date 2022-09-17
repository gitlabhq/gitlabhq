# frozen_string_literal: true

module Deployments
  class DeploymentPresenter < Gitlab::View::Presenter::Delegated
    presents ::Deployment, as: :deployment

    delegator_override :tags
    def tags
      super.map do |tag|
        {
          name: tag,
          path: "tags/#{tag}"
        }
      end
    end
  end
end
