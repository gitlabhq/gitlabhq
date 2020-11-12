# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Link < Grape::Entity
        expose :id
        expose :name
        expose :url
        expose :direct_asset_url
        expose :external?, as: :external
        expose :link_type

        def direct_asset_url
          return object.url unless object.filepath

          release = object.release.present
          release.download_url(object.filepath)
        end
      end
    end
  end
end
