# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Wiki' do
      describe 'testing wiki content creation inside a project' do
        let(:new_wiki_title) { "just_another_wiki_page" }
        let(:new_wiki_content) { "this content is changed or added" }
        let(:commit_message) { "this is a new addition to the wiki" }

        let(:project) { Resource::Project.fabricate_via_api! }
        let(:wiki) { Resource::Wiki::ProjectPage.fabricate_via_api! }

        before do
          Flow::Login.sign_in
        end

        it 'by adding a home page to the wiki', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/856' do
          project.visit!

          Page::Project::Menu.perform(&:click_wiki)
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

        it 'by adding a second page to the wiki', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/855' do
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

        it 'by adding a home page to the wiki using git push', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/853' do
          empty_wiki = Resource::Wiki::ProjectPage.new do |empty_wiki|
            empty_wiki.project = project
          end

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

        it 'by adding a second page to the wiki using git push', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/854' do
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
      end
    end
  end
end
