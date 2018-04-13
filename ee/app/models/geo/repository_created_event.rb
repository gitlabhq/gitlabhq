module Geo
  class RepositoryCreatedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :project

    validates :project, :project_name, :repo_path, :repository_storage_name, presence: true
  end
end
