module Clusters
  module Kubernetes
    def self.table_name_prefix
      'clusters_kubernetes_'
    end

    def self.app(app_name)
      case app_name
      when HelmApp::NAME
        HelmApp
      else
        raise ArgumentError, "Unknown app #{app_name}"
      end
    end
  end
end
