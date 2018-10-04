module QA
  module Page
    module Project
      module Fork
        class New < Page::Base
          view 'app/views/projects/forks/_fork_button.html.haml' do
            element :namespace, 'link_to project_forks_path'
          end

          def choose_namespace(namespace = Runtime::Namespace.path)
            click_on namespace
          end
        end
      end
    end
  end
end
