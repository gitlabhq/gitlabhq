module ClusterApplications
  extend ActiveSupport::Concern

  included do
    def find_application(app_name, id, &blk)
      Clusters::Cluster::APPLICATIONS[app_name].find(id).try(&blk)
    end
  end
end
