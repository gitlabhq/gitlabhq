# frozen_string_literal: true

module API
  module Entities
    module Terraform
      class ModuleVersions < Grape::Entity
        expose :modules
      end
    end
  end
end
