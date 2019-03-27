# frozen_string_literal: true

module QA
  module Resource
    class Snippet < Base
      attr_accessor :title, :description, :file_content, :visibility, :file_name

      def initialize
        @title = 'New snippet title'
        @description = 'The snippet description'
        @visibility = 'Public'
        @file_content = 'The snippet content'
        @file_name = 'New snippet file name'
      end

      def fabricate!
        Page::Dashboard::Snippet::Index.perform(&:go_to_new_snippet_page)

        Page::Dashboard::Snippet::New.perform do |page|
          page.fill_title(@title)
          page.fill_description(@description)
          page.set_visibility(@visibility)
          page.fill_file_name(@file_name)
          page.fill_file_content(@file_content)
          page.create_snippet
        end
      end
    end
  end
end
