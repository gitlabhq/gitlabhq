module Geo
  class RepositoryCreatedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :project

    validates :project, :project_name, :repo_path, :repository_storage_name,
              :repository_storage_path, presence: true
  end
end
