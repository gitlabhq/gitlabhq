# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Testing project wiki', product_group: :knowledge do
      let(:initial_wiki) { create(:project_wiki_page) }

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
    end
  end
end
