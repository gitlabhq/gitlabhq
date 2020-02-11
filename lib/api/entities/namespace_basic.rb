# frozen_string_literal: true

module API
  module Entities
    class NamespaceBasic < Grape::Entity
      expose :id, :name, :path, :kind, :full_path, :parent_id, :avatar_url

      expose :web_url do |namespace|
        if namespace.user?
          Gitlab::Routing.url_helpers.user_url(namespace.owner)
        else
          namespace.web_url
        end
      end
    end
  end
end
