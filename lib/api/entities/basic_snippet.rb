# frozen_string_literal: true

module API
  module Entities
    class BasicSnippet < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :title, documentation: { type: 'String', example: 'test' }
      expose :description, documentation: { type: 'String', example: 'Ruby test snippet' }
      expose :visibility, documentation: { type: 'String', example: 'public' }
      expose :author, using: Entities::UserBasic, documentation: { type: 'Entities::UserBasic' }
      expose :created_at, documentation: { type: 'DateTime', example: '2012-06-28T10:52:04Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2012-06-28T10:52:04Z' }
      expose :project_id, documentation: { type: 'Integer', example: 1 }
      expose :web_url, documentation: {
        type: 'String', example: 'http://example.com/example/example/snippets/1'
      } do |snippet|
        Gitlab::UrlBuilder.build(snippet)
      end
      expose :raw_url, documentation: {
        type: 'String', example: 'http://example.com/example/example/snippets/1/raw'
      } do |snippet|
        Gitlab::UrlBuilder.build(snippet, raw: true)
      end
      expose :ssh_url_to_repo, documentation: {
        type: 'String', example: 'ssh://user@gitlab.example.com/snippets/65.git'
      }, if: ->(snippet) { snippet.repository_exists? }
      expose :http_url_to_repo, documentation: {
        type: 'String', example: 'https://gitlab.example.com/snippets/65.git'
      }, if: ->(snippet) { snippet.repository_exists? }
    end
  end
end
