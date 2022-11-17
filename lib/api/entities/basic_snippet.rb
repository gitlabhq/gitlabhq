# frozen_string_literal: true

module API
  module Entities
    class BasicSnippet < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :title, documentation: { type: 'string', example: 'test' }
      expose :description, documentation: { type: 'string', example: 'Ruby test snippet' }
      expose :visibility, documentation: { type: 'string', example: 'public' }
      expose :author, using: Entities::UserBasic, documentation: { type: 'Entities::UserBasic' }
      expose :created_at, documentation: { type: 'dateTime', example: '2012-06-28T10:52:04Z' }
      expose :updated_at, documentation: { type: 'dateTime', example: '2012-06-28T10:52:04Z' }
      expose :project_id, documentation: { type: 'integer', example: 1 }
      expose :web_url, documentation: {
        type: 'string', example: 'http://example.com/example/example/snippets/1'
      } do |snippet|
        Gitlab::UrlBuilder.build(snippet)
      end
      expose :raw_url, documentation: {
        type: 'string', example: 'http://example.com/example/example/snippets/1/raw'
      } do |snippet|
        Gitlab::UrlBuilder.build(snippet, raw: true)
      end
      expose :ssh_url_to_repo, documentation: {
        type: 'string', example: 'ssh://user@gitlab.example.com/snippets/65.git'
      }, if: ->(snippet) { snippet.repository_exists? }
      expose :http_url_to_repo, documentation: {
        type: 'string', example: 'https://gitlab.example.com/snippets/65.git'
      }, if: ->(snippet) { snippet.repository_exists? }
    end
  end
end
