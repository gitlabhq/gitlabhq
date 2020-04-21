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
      expose :ssh_url_to_repo, :http_url_to_repo, if: ->(snippet) { snippet.versioned_enabled_for?(options[:current_user]) }
      expose :file_name do |snippet|
        (::Feature.enabled?(:version_snippets, options[:current_user]) && snippet.file_name_on_repo) ||
          snippet.file_name
      end
    end
  end
end
