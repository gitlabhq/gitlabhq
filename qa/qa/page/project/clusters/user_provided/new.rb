module QA
  module Page
    module Project
      module Clusters
        module UserProvided
          class New < Page::Base
            view 'app/views/projects/clusters/new.html.haml' do
              element :name_field, 'text_field :name'
              element :environment_scope_field, 'text_field :environment_scope'
              element :api_url_field, 'text_field :api_url'
              element :ca_cert_field, 'text_field :ca_cert'
              element :token_field, 'text_field :token'
              element :namespace_field, 'text_field :namespace'
              element :submit, "submit 'Add Kubernetes cluster'"
            end

            def go_to_new_cluster
              click_link('Add Kubernetes cluster')
            end
          end
        end
      end
    end
  end
end
