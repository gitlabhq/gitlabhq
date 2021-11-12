# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class Index < Page::Base
            view 'app/views/clusters/clusters/_cluster_list.html.haml' do
              element :integrate_kubernetes_cluster_button
            end

            def connect_cluster_with_certificate
              find('.js-add-cluster').click
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
