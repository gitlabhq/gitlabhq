# frozen_string_literal: true

# TODO: remove this test when coverage is replaced or deemed irrelevant
module QA
  RSpec.describe 'Create', :skip_live_env, product_group: :ide do
    before do
      skip("Skipped but kept as reference. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741#note_1330720944")
    end

    describe 'Open Web IDE from Diff Tab' do
      files = [
        {
            file_path: 'file1',
            content: 'test1'
        },
        {
            file_path: 'file2',
            content: 'test2'
        },
        {
            file_path: 'file3',
            content: 'test3'
        }
      ]

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.initialize_with_readme = true
        end
      end

      let(:source) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.branch = 'new-mr'
          commit.start_branch = project.default_branch
          commit.commit_message = 'Add new files'
          commit.add_files(files)
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.source = source
          mr.project = project
          mr.source_branch = 'new-mr'
          mr.target_new_branch = false
        end
      end

      before do
        Flow::Login.sign_in
        merge_request.visit!
      end

      it 'opens and edits a multi-file merge request in Web IDE from Diff Tab', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347724' do
        Page::MergeRequest::Show.perform do |show|
          show.click_diffs_tab
          show.edit_file_in_web_ide('file1')
        end

        Page::Project::WebIDE::Edit.perform do |ide|
          ide.wait_until_ide_loads
          files.each do |files|
            expect(ide).to have_file(files[:file_path])
            expect(ide).to have_file_content(files[:file_path], files[:content])
          end

          ide.delete_file('file1')
          ide.commit_changes
        end

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.click_diffs_tab

          expect(show).not_to have_file('file1')
          expect(show).to have_file('file2')
          expect(show).to have_file('file3')
        end
      end
    end
  end
end
