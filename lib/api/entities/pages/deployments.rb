# frozen_string_literal: true

module API
  module Entities
    module Pages
      class Deployments < Grape::Entity
        expose :created_at
        expose :url
        expose :path_prefix
        expose :root_directory
      end
    end
  end
end
