require_dependency 'lib/gitlab/kubernetes/helm.rb'

module Gitlab
  module Kubernetes
    module Helm
      class GetCommand < BaseCommand
        def config_map?
          true
        end

        def config_map_name
          ::Gitlab::Kubernetes::ConfigMap.new(name).config_map_name
        end
      end
    end
  end
end
