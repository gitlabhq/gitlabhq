# frozen_string_literal: true

module API
  module Entities
    class Snippet < Grape::Entity
      expose :id, :title, :file_name, :description, :visibility
      expose :author, using: Entities::UserBasic
      expose :updated_at, :created_at
      expose :project_id
      expose :web_url do |snippet|
        Gitlab::UrlBuilder.build(snippet)
      end
    end
  end
end
