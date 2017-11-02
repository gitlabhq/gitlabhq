module ClusterApp
  extend ActiveSupport::Concern

  included do
    def find_app(app_name, id)
      app = Clusters::Kubernetes.app(app_name).find(id)
      yield(app) if block_given?
    end
  end
end
