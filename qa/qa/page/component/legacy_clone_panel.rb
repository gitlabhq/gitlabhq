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
            element :clone_dropdown_content
            element :clone_url_content
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
          Git::Location.new(find_element(:clone_url_content).value)
        end

        private

        def choose_repository_clone(kind, detect_text)
          wait_until(reload: false) do
            click_element :clone_dropdown

            within_element(:clone_dropdown_content) do
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
