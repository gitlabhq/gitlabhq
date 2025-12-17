# frozen_string_literal: true

module API
  module Entities
    module Organizations
      class Organization < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :name, documentation: { type: 'String', example: 'GitLab' }
        expose :path, documentation: { type: 'String', example: 'gitlab' }
        expose :description, documentation: { type: 'String', example: 'My description' }
        expose :created_at, documentation: { type: 'DateTime', example: '2022-02-24T20:22:30.097Z' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2022-02-24T20:22:30.097Z' }
        expose :web_url, documentation: { type: 'String', example: "https://example.com/-/organizations/gitlab" }
        expose(:avatar_url, documentation: {
          type: 'String',
          example: 'https://example.com/uploads/-/system/organizations/organization_detail/avatar/1/avatar.png'
        }) do |organization, _options|
          organization.avatar_url(only_path: false)
        end
      end
    end
  end
end
