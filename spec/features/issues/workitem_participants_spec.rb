# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'viewing participants of an issue', :js, feature_category: :service_desk do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user, :with_namespace, reporter_of: project) }

  let_it_be_with_refind(:issue) { create(:issue, project: project) }

  before do
    sign_in(user)
  end

  shared_examples 'shows participants in the sidebar' do |selector_participants_element:|
    it 'shows the correct number of participants in the sidebar' do
      visit project_issue_path(project, issue)

      wait_for_requests

      within(selector_participants_element) do
        expect(page).to have_content('1 Participant')
      end
    end

    context 'when the issue has more participants than the default max page size of the GraphQL API' do
      let_it_be(:note_participants) do
        create_list(:user, 2) { |user| create(:note_on_issue, project: project, noteable: issue, author: user) }
      end

      before do
        #  On production, the default max page size is 100,
        #  but we want to test with a smaller size
        #  in order to avoid creating too many note participants.
        allow(GitlabSchema).to receive(:default_max_page_size).and_return(2)
      end

      it 'shows the correct number of participants in the sidebar' do
        visit project_issue_path(project, issue)

        wait_for_requests

        within(selector_participants_element) do
          expect(page).to have_content('3 Participants')
        end
      end
    end
  end

  it_behaves_like 'shows participants in the sidebar',
    selector_participants_element: '.block.participants'

  context 'when work_item_view_for_issues is enabled' do
    before do
      stub_feature_flags(work_item_view_for_issues: true)
    end

    it_behaves_like 'shows participants in the sidebar',
      selector_participants_element: '[data-testid="work-item-participants"]'
  end
end
