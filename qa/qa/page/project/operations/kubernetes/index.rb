# frozen_string_literal: true

module QA
  module Page
    module Project
      module Operations
        module Kubernetes
          class Index < Page::Base
            view 'app/views/clusters/clusters/_empty_state.html.haml' do
              element :add_kubernetes_cluster_button, "link_to s_('ClusterIntegration|Add Kubernetes cluster')" # rubocop:disable QA/ElementWithPattern
            end

            def add_kubernetes_cluster
              click_on 'Add Kubernetes cluster'
            end

            def has_cluster?(cluster)
              has_element?(:cluster, cluster_name: cluster.to_s)
            end
          end
        end
      end
    end
  end
end
