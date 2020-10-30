# frozen_string_literal: true

module QA
  module Resource
    class Snippet < Base
      attr_accessor :title, :description, :file_content, :visibility, :file_name, :snippet_id

      def initialize
        @title = 'New snippet title'
        @description = 'The snippet description'
        @visibility = 'Public'
        @file_content = 'The snippet content'
        @file_name = 'New snippet file name'
        @files = []
      end

      def add_files
        yield @files
      end

      def fabricate!
        Page::Dashboard::Snippet::Index.perform(&:go_to_new_snippet_page)

        Page::Dashboard::Snippet::New.perform do |new_page|
          new_page.fill_title(@title)
          new_page.fill_description(@description)
          new_page.set_visibility(@visibility)
          new_page.fill_file_name(@file_name)
          new_page.fill_file_content(@file_content)

          @files.each.with_index(2) do |file, i|
            new_page.click_add_file
            new_page.fill_file_name(file[:name], i)
            new_page.fill_file_content(file[:content], i)
          end
          new_page.click_create_snippet_button
        end
      end

      def fabricate_via_api!
        resource_web_url(api_post)
      rescue ResourceNotFoundError
        super
      end

      def api_get_path
        "/snippets/#{snippet_id}"
      end

      def api_post_path
        '/snippets'
      end

      def api_post_body
        {
            title: title,
            description: description,
            visibility: visibility.downcase,
            files: all_file_contents
        }
      end

      def all_file_contents
        @files.insert(0, { name: @file_name, content: @file_content })
        @files.each do |file|
          file[:file_path] = file.delete(:name)
        end
      end
    end
  end
end
