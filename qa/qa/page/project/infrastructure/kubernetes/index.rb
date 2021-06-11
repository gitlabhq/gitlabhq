# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class Index < Page::Base
            view 'app/views/clusters/clusters/_empty_state.html.haml' do
              element :add_kubernetes_cluster_link
            end

            def add_kubernetes_cluster
              click_element :add_kubernetes_cluster_link
            end

            def has_cluster?(cluster)
              has_element?(:cluster, cluster_name: cluster.to_s)
            end

            def click_on_cluster(cluster)
              click_on cluster.cluster_name
            end
          end
        end
      end
    end
  end
end
