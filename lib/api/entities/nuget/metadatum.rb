# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class Metadatum < Grape::Entity
        expose :authors, documentation: { type: 'string', example: 'Authors' } do |metadatum|
          metadatum[:authors] || ''
        end
        expose :description, as: :summary, documentation: { type: 'string', example: 'Description' } do |metadatum|
          metadatum[:description] || ''
        end
        expose :project_url, as: :projectUrl, expose_nil: false, documentation: { type: 'string', example: 'http://sandbox.com/project' }
        expose :license_url, as: :licenseUrl, expose_nil: false, documentation: { type: 'string', example: 'http://sandbox.com/license' }
        expose :icon_url, as: :iconUrl, expose_nil: false, documentation: { type: 'string', example: 'http://sandbox.com/icon' }
      end
    end
  end
end
