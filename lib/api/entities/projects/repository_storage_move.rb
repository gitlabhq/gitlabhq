# frozen_string_literal: true

module API
  module Entities
    module Projects
      class RepositoryStorageMove < BasicRepositoryStorageMove
        expose :project, using: Entities::ProjectIdentity
      end
    end
  end
end
