# frozen_string_literal: true

module API
  module Entities
    class Snippet < Grape::Entity
      expose :id, :title, :description, :visibility
      expose :author, using: Entities::UserBasic
      expose :updated_at, :created_at
      expose :project_id
      expose :web_url do |snippet|
        Gitlab::UrlBuilder.build(snippet)
      end
      expose :raw_url do |snippet|
        Gitlab::UrlBuilder.build(snippet, raw: true)
      end
      expose :ssh_url_to_repo, :http_url_to_repo, if: ->(snippet) { snippet.repository_exists? }
      expose :file_name do |snippet|
        snippet.file_name_on_repo || snippet.file_name
      end
      expose :files, if: ->(snippet, options) { snippet_multiple_files?(snippet, options[:current_user]) } do |snippet, options|
        snippet.list_files.map do |file|
          {
            path: file,
            raw_url: Gitlab::UrlBuilder.build(snippet, file: file, ref: snippet.repository.root_ref)
          }
        end
      end

      def snippet_multiple_files?(snippet, current_user)
        ::Feature.enabled?(:snippet_multiple_files, current_user) && snippet.repository_exists?
      end
    end
  end
end
