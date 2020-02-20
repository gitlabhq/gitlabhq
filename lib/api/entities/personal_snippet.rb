# frozen_string_literal: true

module API
  module Entities
    class PersonalSnippet < Snippet
      expose :raw_url do |snippet|
        Gitlab::UrlBuilder.build(snippet, raw: true)
      end
    end
  end
end
