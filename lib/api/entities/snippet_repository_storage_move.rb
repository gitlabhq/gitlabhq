# frozen_string_literal: true

module API
  module Entities
    class SnippetRepositoryStorageMove < BasicRepositoryStorageMove
      expose :snippet, using: ::API::Entities::BasicSnippet, documentation: { type: '::API::Entities::BasicSnippet' }
    end
  end
end
