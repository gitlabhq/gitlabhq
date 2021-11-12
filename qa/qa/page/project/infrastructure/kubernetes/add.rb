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
              page.find('.gl-tab-nav-item', text: 'Connect existing cluster').click
            end
          end
        end
      end
    end
  end
end
