module Geo
  class RepositoryRenamedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :project

    validates :project, :repository_storage_name, :repository_storage_path,
              :old_repo_path_with_namespace, :new_repo_path_with_namespace,
              :old_wiki_path_with_namespace, :new_wiki_path_with_namespace,
              :old_project_name, :new_project_name, presence: true
  end
end
