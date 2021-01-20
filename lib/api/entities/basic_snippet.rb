# frozen_string_literal: true

module API
  module Entities
    class BasicSnippet < Grape::Entity
      expose :id, :title, :description, :visibility
      expose :updated_at, :created_at
      expose :project_id
      expose :web_url do |snippet|
        Gitlab::UrlBuilder.build(snippet)
      end
      expose :raw_url do |snippet|
        Gitlab::UrlBuilder.build(snippet, raw: true)
      end
      expose :ssh_url_to_repo, :http_url_to_repo, if: ->(snippet) { snippet.repository_exists? }
    end
  end
end
