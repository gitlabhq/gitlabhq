# frozen_string_literal: true

module API
  module Entities
    module Terraform
      class ModuleVersion < Grape::Entity
        expose :name
        expose :provider
        expose :providers
        expose :root
        expose :source
        expose :submodules
        expose :version
        expose :versions
      end
    end
  end
end
