# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Link < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :name, documentation: { type: 'String', example: 'app-v1.0.dmg' }
        expose :url, documentation:
          {
            type: 'String',
            example: 'https://gitlab.example.com/root/app/-/jobs/688/artifacts/raw/bin/app-v1.0.dmg'
          }
        expose :direct_asset_url, documentation:
          {
            type: 'String',
            example: 'https://gitlab.example.com/root/app/-/releases/v1.0/downloads/app-v1.0.dmg'
          } do |link|
          ::Releases::LinkPresenter.new(link).direct_asset_url
        end
        expose :link_type, documentation: { type: 'String', example: 'other' }
      end
    end
  end
end
