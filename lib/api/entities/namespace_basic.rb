# frozen_string_literal: true

module API
  module Entities
    class NamespaceBasic < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 2 }
      expose :name, documentation: { type: 'string', example: 'project' }
      expose :path, documentation: { type: 'string', example: 'my_project' }
      expose :kind, documentation: { type: 'string', example: 'project' }
      expose :full_path, documentation: { type: 'string', example: 'group/my_project' }
      expose :parent_id, documentation: { type: 'integer', example: 1 }
      expose :avatar_url, documentation: { type: 'string', example: 'https://example.com/avatar/12345' }

      expose :web_url, documentation: { type: 'string', example: 'https://example.com/group/my_project' } do |namespace|
        if namespace.user_namespace?
          Gitlab::Routing.url_helpers.user_url(namespace.owner || namespace.route.path)
        else
          namespace.web_url
        end
      end
    end
  end
end
