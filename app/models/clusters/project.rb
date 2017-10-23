module Clusters
  class Project < ActiveRecord::Base
    self.table_name = 'cluster_projects'

    belongs_to :cluster, inverse_of: :projects, class_name: 'Clusters::Cluster'
    belongs_to :project, inverse_of: :project, class_name: 'Project'
  end
end
