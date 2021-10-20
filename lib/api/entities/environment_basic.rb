# frozen_string_literal: true

module API
  module Entities
    class EnvironmentBasic < Grape::Entity
      expose :id, :name, :slug, :external_url, :created_at, :updated_at
    end
  end
end
