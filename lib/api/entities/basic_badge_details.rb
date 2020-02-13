# frozen_string_literal: true

module API
  module Entities
    class BasicBadgeDetails < Grape::Entity
      expose :name
      expose :link_url
      expose :image_url
      expose :rendered_link_url do |badge, options|
        badge.rendered_link_url(options.fetch(:project, nil))
      end
      expose :rendered_image_url do |badge, options|
        badge.rendered_image_url(options.fetch(:project, nil))
      end
    end
  end
end
