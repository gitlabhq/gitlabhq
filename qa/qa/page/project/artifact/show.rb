# frozen_string_literal: true

module QA
  module Page
    module Project
      module Artifact
        class Show < QA::Page::Base
          view 'app/views/projects/artifacts/_tree_directory.html.haml' do
            element 'directory-name-link'
          end

          def go_to_directory(name, retry_attempts = 1)
            retry_on_exception(max_attempts: retry_attempts, reload: true, sleep_interval: 10) do
              click_element('directory-name-link', directory_name: name)
            end
          end
        end
      end
    end
  end
end
