# frozen_string_literal: true

module QA
  module Page
    module Project
      module Artifact
        class Show < QA::Page::Base
          view 'app/views/projects/artifacts/_tree_directory.html.haml' do
            element :directory_name_link
          end

          def go_to_directory(name)
            click_element(:directory_name_link, directory_name: name)
          end
        end
      end
    end
  end
end
