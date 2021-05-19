# frozen_string_literal: true

module API
  module Entities
    class DeployToken < Grape::Entity
      # exposing :token is a security risk and should be avoided
      expose :id, :name, :username, :expires_at, :scopes, :revoked
      expose :expired?, as: :expired
    end
  end
end
