require_dependency 'gitlab/kubernetes/helm.rb'

module Gitlab
  module Kubernetes
    module Helm
      class GetCommand
        include BaseCommand

        attr_reader :name

        def initialize(name)
          @name = name
        end

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
