# frozen_string_literal: true

module API
  module Entities
    class DeployToken < Grape::Entity
      expose :id, :name, :username, :expires_at, :token, :scopes
    end
  end
end
