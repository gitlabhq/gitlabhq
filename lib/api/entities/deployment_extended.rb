# frozen_string_literal: true

module API
  module Entities
    class DeploymentExtended < Deployment
    end
  end
end

API::Entities::DeploymentExtended.prepend_mod
