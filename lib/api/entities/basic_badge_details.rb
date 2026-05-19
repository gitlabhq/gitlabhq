# frozen_string_literal: true

module API
  module Entities
    class BasicBadgeDetails < Grape::Entity
      expose :name, documentation: { type: 'String', example: 'Pipeline Status' }
      expose :link_url, documentation: { type: 'String', example: 'https://example.gitlab.com' }
      expose :image_url, documentation: { type: 'String', example: 'https://example.gitlab.com' }
      expose :rendered_link_url,
        documentation: { type: 'String', example: 'https://example.gitlab.com' } do |badge, options|
        Addressable::URI.escape(badge.rendered_link_url(options.fetch(:project, nil)))
      end
      expose :rendered_image_url,
        documentation: { type: 'String', example: 'https://example.gitlab.com' } do |badge, options|
        Addressable::URI.escape(badge.rendered_image_url(options.fetch(:project, nil)))
      end
    end
  end
end
