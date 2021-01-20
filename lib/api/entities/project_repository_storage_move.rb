# frozen_string_literal: true

module API
  module Entities
    class ProjectRepositoryStorageMove < BasicRepositoryStorageMove
      expose :project, using: Entities::ProjectIdentity
    end
  end
end
