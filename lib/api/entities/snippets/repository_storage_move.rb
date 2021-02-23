# frozen_string_literal: true

module API
  module Entities
    module Snippets
      class RepositoryStorageMove < BasicRepositoryStorageMove
        expose :snippet, using: Entities::BasicSnippet
      end
    end
  end
end
