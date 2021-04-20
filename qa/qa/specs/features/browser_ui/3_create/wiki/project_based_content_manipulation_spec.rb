# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Wiki' do
      describe 'testing wiki content manipulation inside a project' do
        let(:new_wiki_title) { "just_another_wiki_page" }
        let(:new_wiki_content) { "this content is changed or added" }
        let(:commit_message) { "this is a new addition to the wiki" }

        let(:wiki) { Resource::Wiki::ProjectPage.fabricate_via_api! }

        before do
          Flow::Login.sign_in
        end

        it 'by manipulating content on the page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/857' do
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

        it 'by manipulating content on the page using git push', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/858' do
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
end
