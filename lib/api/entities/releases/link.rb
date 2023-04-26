# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Link < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :name, documentation: { type: 'string', example: 'app-v1.0.dmg' }
        expose :url, documentation:
          {
            type: 'string',
            example: 'https://gitlab.example.com/root/app/-/jobs/688/artifacts/raw/bin/app-v1.0.dmg'
          }
        expose :direct_asset_url, documentation:
          {
            type: 'string',
            example: 'https://gitlab.example.com/root/app/-/releases/v1.0/downloads/app-v1.0.dmg'
          } do |link|
          ::Releases::LinkPresenter.new(link).direct_asset_url
        end
        expose :link_type, documentation: { type: 'string', example: 'other' }
      end
    end
  end
end
