# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Wiki' do
      let(:initial_wiki) { Resource::Wiki::ProjectPage.fabricate_via_api! }

      before do
        Flow::Login.sign_in
      end

      context 'Page deletion' do
        it 'has removed the deleted page correctly', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/921' do
          initial_wiki.visit!

          Page::Project::Wiki::Show.perform(&:click_edit)
          Page::Project::Wiki::Edit.perform(&:delete_page)

          Page::Project::Wiki::Show.perform do |wiki|
            expect(wiki).to have_no_page
          end
        end
      end
    end
  end
end
