# frozen_string_literal: true

module API
  module Entities
    class SnippetRepositoryStorageMove < BasicRepositoryStorageMove
      expose :snippet, using: Entities::BasicSnippet
    end
  end
end
