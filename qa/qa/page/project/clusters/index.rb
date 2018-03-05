module QA
  module Page
    module Project
      module Clusters
        class Index < Page::Base
          view 'app/views/projects/clusters/index.html.haml' do
            element :add_cluster_link, title: 'Add Kubernetes cluster'
          end

          def go_to_new_cluster
            click_link('Add Kubernetes cluster')
          end
        end
      end
    end
  end
end
