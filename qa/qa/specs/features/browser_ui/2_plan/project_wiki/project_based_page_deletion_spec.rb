# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Testing project wiki', product_group: :knowledge do
      let(:initial_wiki) { create(:project_wiki_page) }
      let(:new_wiki_page_with_spaces_in_the_path) { "a wiki page with spaces in the path" }
      let(:new_wiki_page_with_spaces_in_the_path_content) { "content for the wiki page with spaces in the path" }
      let(:commit_message) { "this is a new addition to the wiki" }

      before do
        Flow::Login.sign_in
      end

      it 'can delete a page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347815' do
        initial_wiki.visit!

        Page::Project::Wiki::Show.perform(&:click_edit)
        Page::Project::Wiki::Edit.perform(&:delete_page)

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_no_page
        end
      end

      it 'can delete a page with spaces in the path',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/442389' do
        Resource::Repository::WikiPush.fabricate! do |push|
          push.file_name = "#{new_wiki_page_with_spaces_in_the_path}.md"
          push.file_content = new_wiki_page_with_spaces_in_the_path_content
          push.commit_message = commit_message
          push.wiki = initial_wiki
          push.new_branch = false
        end.visit!

        Page::Project::Wiki::Show.perform(&:click_edit)
        Page::Project::Wiki::Edit.perform(&:delete_page)

        Page::Project::Wiki::Show.perform do |wiki|
          expect(wiki).to have_page_listed("Home")
          expect(wiki).not_to have_page_listed(new_wiki_page_with_spaces_in_the_path)
        end
      end
    end
  end
end
