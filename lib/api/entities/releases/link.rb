# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Link < Grape::Entity
        expose :id
        expose :name
        expose :url
        expose :direct_asset_url do |link|
          ::Releases::LinkPresenter.new(link).direct_asset_url
        end
        expose :external?, as: :external
        expose :link_type
      end
    end
  end
end
