# frozen_string_literal: true

module API
  module Entities
    module Pages
      class ProjectSettings < Grape::Entity
        expose :url
        expose :deployments, using: "API::Entities::Pages::Deployments"
        expose :unique_domain_enabled?, as: :is_unique_domain_enabled
        expose :force_https?, as: :force_https
        expose :pages_primary_domain
      end
    end
  end
end
