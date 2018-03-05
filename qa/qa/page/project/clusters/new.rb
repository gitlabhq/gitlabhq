module QA
  module Page
    module Project
      module Clusters
        class New < Page::Base
          view 'app/views/projects/clusters/new.html.haml' do
            element :add_cluster_link, title: 'Add an existing Kubernetes cluster'
          end

          def add_an_existing_cluster
            click_link('Add an existing Kubernetes cluster')
          end
        end
      end
    end
  end
end
