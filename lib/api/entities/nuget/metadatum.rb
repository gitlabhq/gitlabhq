# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class Metadatum < Grape::Entity
        expose :project_url, as: :projectUrl, expose_nil: false
        expose :license_url, as: :licenseUrl, expose_nil: false
        expose :icon_url, as: :iconUrl, expose_nil: false
      end
    end
  end
end
