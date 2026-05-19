# frozen_string_literal: true

module API
  module Entities
    module Projects
      class RepositoryStorageMove < BasicRepositoryStorageMove
        expose :project, using: ::API::Entities::ProjectIdentity
      end
    end
  end
end
