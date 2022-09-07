# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class Index < Page::Base
            view 'app/assets/javascripts/clusters_list/components/clusters_actions.vue' do
              element :clusters_actions_button
            end

            def connect_cluster
              click_element(:clusters_actions_button)
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
