# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :knowledge do
    describe 'Testing wiki content creation inside a project' do
      let(:new_wiki_title) { "just_another_wiki_page" }
      let(:new_wiki_content) { "this content is changed or added" }
      let(:new_wiki_page_with_spaces_in_the_path) { "a wiki page with spaces in the path" }
      let(:new_wiki_page_with_spaces_in_the_path_content) { "content for the wiki page with spaces in the path" }
      let(:commit_message) { "this is a new addition to the wiki" }

      let(:project) { create(:project) }
      let(:wiki) { create(:project_wiki_page) }

      before do
        Flow::Login.sign_in
      end

      it 'by adding a home page to the wiki',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347809' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_wiki)
        Page::Project::Wiki::Show.perform(&:click_create_your_first_page)

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

      it 'by adding a second page to the wiki',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347808' do
        wiki.visit!

        Page::Project::Wiki::Show.perform(&:click_new_page)

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

      it 'by adding a home page to the wiki using git push',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347806' do
        empty_wiki = build(:project_wiki_page, project: project)

        Resource::Repository::WikiPush.fabricate! do |push|
          push.file_name = "#{new_wiki_title}.md"
          push.file_content = new_wiki_content
          push.commit_message = commit_message
          push.wiki = empty_wiki
          push.new_branch = true
        end.visit!

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_title new_wiki_title
          expect(wiki).to have_content new_wiki_content
        end
      end

      it 'by adding a second page to the wiki using git push',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347807' do
        Resource::Repository::WikiPush.fabricate! do |push|
          push.file_name = "#{new_wiki_title}.md"
          push.file_content = new_wiki_content
          push.commit_message = commit_message
          push.wiki = wiki
          push.new_branch = false
        end.visit!

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_title new_wiki_title
          expect(wiki).to have_content new_wiki_content
        end
      end

      it 'by adding a wiki page with spaces in the path using git push',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/442387' do
        Resource::Repository::WikiPush.fabricate! do |push|
          push.file_name = "#{new_wiki_page_with_spaces_in_the_path}.md"
          push.file_content = new_wiki_page_with_spaces_in_the_path_content
          push.commit_message = commit_message
          push.wiki = wiki
          push.new_branch = false
        end.visit!

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_title new_wiki_page_with_spaces_in_the_path
          expect(wiki).to have_content new_wiki_page_with_spaces_in_the_path_content
        end
      end
    end
  end
end
