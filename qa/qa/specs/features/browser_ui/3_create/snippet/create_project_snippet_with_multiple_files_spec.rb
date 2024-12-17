# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'Multiple file snippet' do
      let(:snippet) do
        Resource::ProjectSnippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Project snippet with multiple files'
          snippet.description = 'Snippet description'
          snippet.visibility = 'Private'
          snippet.file_name = '01 file name'
          snippet.file_content = '1 file content'

          # Ten is the limit of files you can have under one snippet at the moment
          snippet.add_files do |files|
            (2..10).each do |i|
              files.append(name: file_name(i), content: file_content(i))
            end
          end
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'creates a project snippet with multiple files', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347725' do
        snippet

        Page::Dashboard::Snippet::Show.perform do |snippet|
          aggregate_failures 'file content verification' do
            expect(snippet).to have_snippet_title('Project snippet with multiple files')
            expect(snippet).to have_snippet_description('Snippet description')
            expect(snippet).to have_visibility_description('The snippet is visible only to project members.')

            (1..10).each do |i|
              expect(snippet).to have_file_name(file_name(i), i)
              expect(snippet).to have_file_content(file_content(i), i)
            end
          end
        end
      end

      # Currently the files are returned in alphabetical order and not in the order they are created.
      # However, it might soon change - see https://gitlab.com/gitlab-org/gitlab/-/issues/250836.
      # By using a leading "0" we make sure the test works with either implementation.
      def file_name(index)
        "#{index.to_s.rjust(2, '0')} file name"
      end

      def file_content(index)
        "#{index} file content"
      end
    end
  end
end
