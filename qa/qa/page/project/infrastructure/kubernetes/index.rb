# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class Index < Page::Base
            view 'app/assets/javascripts/clusters_list/components/clusters_view_all.vue' do
              element :connect_existing_cluster_button
            end

            def connect_existing_cluster
              click_link 'Connect existing cluster'
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
