# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Wiki' do
      let(:initial_wiki) { Resource::Wiki::ProjectPage.fabricate_via_api! }
      let(:new_path) { "a/new/path-with-spaces" }

      before do
        Flow::Login.sign_in
      end

      it 'has changed the directory', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/948' do
        initial_wiki.visit!

        Page::Project::Wiki::Show.perform(&:click_edit)

        Page::Project::Wiki::Edit.perform do |edit|
          edit.set_title("#{new_path}/home")
          edit.set_message('changing the path of the home page')
        end

        Page::Project::Wiki::Edit.perform(&:click_submit)

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_directory('a')
          expect(wiki).to have_directory('new')
          expect(wiki).to have_directory('path with spaces')
        end
      end
    end
  end
end
