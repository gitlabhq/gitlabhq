# frozen_string_literal: true

module QA
  module Page
    module Blame
      class Show < Page::Base
        view 'app/views/projects/blob/_header_content.html.haml' do
          element 'file-name-content'
        end

        view 'app/views/projects/blame/show.html.haml' do
          element 'blob-content-holder'
        end

        def has_file?(file_name)
          within_element('file-name-content') { has_text?(file_name) }
        end

        def has_no_file?(file_name)
          within_element('file-name-content') do
            has_no_text?(file_name)
          end
        end

        def has_file_content?(file_content)
          within_element('blob-content-holder') { has_text?(file_content) }
        end

        def has_no_file_content?(file_content)
          within_element('blob-content-holder') do
            has_no_text?(file_content)
          end
        end
      end
    end
  end
end
