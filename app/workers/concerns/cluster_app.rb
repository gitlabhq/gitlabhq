module ClusterApp
  extend ActiveSupport::Concern

  included do
    def find_app(app_name, id)
      Clusters::Cluster::APPLICATIONS[app_name].find(id).try do |app|
        yield(app) if block_given?
      end
    end
  end
end
