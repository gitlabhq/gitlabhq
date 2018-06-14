module QA
  module Page
    module Project
      module Wiki
        class Show < Page::Base
          include Page::Shared::ClonePanel
          view 'app/views/shared/_clone_panel.html.haml' do
            element :clone_dropdown
            element :clone_options_dropdown, '.clone-options-dropdown'
            element :project_repository_location, 'text_field_tag :project_clone'
          end

          view 'app/views/projects/wikis/pages.html.haml' do
            element :clone_repository_link, 'Clone repository'
          end

          def go_to_clone_repository
            click_on 'Clone repository'
          end
        end
      end
    end
  end
end
