# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :knowledge do
    describe 'Testing wiki content manipulation inside a project' do
      let(:new_wiki_title) { "just_another_wiki_page" }
      let(:new_wiki_content) { "this content is changed or added" }
      let(:new_wiki_page_with_spaces_in_the_path) { "a wiki page with spaces in the path" }
      let(:new_wiki_page_with_dashes_in_the_path) { "a-wiki-page-with-spaces-in-the-path" }
      let(:new_wiki_page_with_spaces_in_the_path_content) { "content for the wiki page with spaces in the path" }
      let(:commit_message) { "this is a new addition to the wiki" }

      let(:wiki) { create(:project_wiki_page) }

      before do
        Flow::Login.sign_in
      end

      it 'by manipulating content on the page',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347810' do
        wiki.visit!

        Page::Project::Wiki::Show.perform(&:click_edit)

        Page::Project::Wiki::Edit.perform do |edit|
          edit.set_title new_wiki_title
          edit.set_content new_wiki_content
          edit.set_message commit_message
        end

        Page::Project::Wiki::Edit.perform(&:click_submit)

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_title new_wiki_title
          expect(wiki).to have_content new_wiki_content
        end
      end

      it 'by manipulating content on the page with spaces',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/442390' do
        Resource::Repository::WikiPush.fabricate! do |push|
          push.file_name = "#{new_wiki_page_with_spaces_in_the_path}.md"
          push.file_content = new_wiki_page_with_spaces_in_the_path_content
          push.commit_message = commit_message
          push.wiki = wiki
          push.new_branch = false
        end.visit!

        Page::Project::Wiki::Show.perform(&:click_edit)

        Page::Project::Wiki::Edit.perform do |edit|
          edit.set_content new_wiki_content
          edit.set_message commit_message
        end

        Page::Project::Wiki::Edit.perform(&:click_submit)

        Page::Project::Wiki::Show.perform do |wiki|
          expect(page).to have_current_path(/#{new_wiki_page_with_dashes_in_the_path}$/)
          expect(wiki).to have_title new_wiki_page_with_spaces_in_the_path
          expect(wiki).to have_content new_wiki_content
        end
      end

      it 'by manipulating content on the page using git push',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347811' do
        Resource::Repository::WikiPush.fabricate! do |push|
          push.file_content = new_wiki_content
          push.commit_message = commit_message
          push.wiki = wiki
          push.new_branch = false
        end.visit!

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_content new_wiki_content
        end
      end
    end
  end
end
