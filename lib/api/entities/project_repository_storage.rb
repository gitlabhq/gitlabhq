# frozen_string_literal: true

module API
  module Entities
    class ProjectRepositoryStorage < Grape::Entity
      include Gitlab::Routing

      expose :disk_path do |project|
        project.repository.disk_path
      end

      expose :id, as: :project_id
      expose :repository_storage, :created_at
    end
  end
end
