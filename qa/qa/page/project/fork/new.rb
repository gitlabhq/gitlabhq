module QA
  module Page
    module Project
      module Fork
        class New < Page::Base
          view 'app/views/projects/forks/new.html.haml' do
            element :fork_button, "fork_button', namespace: namespace"
          end

          def choose_namespace(namespace_name)
            click_on namespace_name
          end
        end
      end
    end
  end
end
