# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      class Author < ::API::Entities::UserBasic
        expose :web_path, documentation: { type: 'String', example: '/root' } do |user|
          Gitlab::Routing.url_helpers.user_path(user)
        end
      end
    end
  end
end
