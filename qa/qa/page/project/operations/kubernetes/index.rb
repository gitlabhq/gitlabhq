module QA
  module Page
    module Project
      module Operations
        module Kubernetes
          class Index < Page::Base
            view 'app/views/projects/clusters/_empty_state.html.haml' do
              element :add_kubernetes_cluster_button, "link_to s_('ClusterIntegration|Add Kubernetes cluster')"
            end

            def add_kubernetes_cluster
              click_on 'Add Kubernetes cluster'
            end
          end
        end
      end
    end
  end
end
