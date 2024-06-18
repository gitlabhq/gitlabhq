# frozen_string_literal: true

module QA
  module Service
    module ClusterProvider
      class Minikube < Base
        def validate_dependencies
          find_executable('minikube') || raise("You must first install `minikube` executable to run these tests.")
        end

        def set_credentials(admin_user); end

        def setup
          shell 'minikube stop'
          shell "minikube profile #{cluster_name}"
          shell 'minikube start'
        end

        def teardown
          shell 'minikube delete'
        end
      end
    end
  end
end
