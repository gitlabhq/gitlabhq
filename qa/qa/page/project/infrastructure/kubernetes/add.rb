# frozen_string_literal: true

module QA
  module Page
    module Project
      module Infrastructure
        module Kubernetes
          class Add < Page::Base
            view 'app/views/clusters/clusters/new.html.haml' do
              element :add_existing_cluster_tab
            end

            def add_existing_cluster
              click_element(:add_existing_cluster_tab)
            end
          end
        end
      end
    end
  end
end
