# frozen_string_literal: true

module QA
  module Page
    module Component
      module LegacyClonePanel
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/shared/_clone_panel.html.haml' do
            element :clone_dropdown
            element :clone_options_dropdown, '.clone-options-dropdown' # rubocop:disable QA/ElementWithPattern
            element :project_repository_location, 'text_field_tag :project_clone' # rubocop:disable QA/ElementWithPattern
          end
        end

        def choose_repository_clone_http
          choose_repository_clone('HTTP', 'http')
        end

        def choose_repository_clone_ssh
          # It's not always beginning with ssh:// so detecting with @
          # would be more reliable because ssh would always contain it.
          # We can't use .git because HTTP also contain that part.
          choose_repository_clone('SSH', '@')
        end

        def repository_location
          Git::Location.new(find('#project_clone').value)
        end

        private

        def choose_repository_clone(kind, detect_text)
          wait_until(reload: false) do
            click_element :clone_dropdown

            page.within('.clone-options-dropdown') do
              click_link(kind)
            end

            # Ensure git clone textbox was updated
            repository_location.git_uri.include?(detect_text)
          end
        end
      end
    end
  end
end
