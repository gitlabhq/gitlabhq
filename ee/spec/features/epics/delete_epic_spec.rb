require 'spec_helper'

describe 'Delete Epic', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let!(:epic2) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when user who is not a group member displays the epic' do
    it 'does not show the Delete button' do
      visit group_epic_path(group, epic)

      expect(page).not_to have_selector('.detail-page-header button')
    end
  end

  context 'when user with owner access displays the epic' do
    before do
      group.add_owner(user)
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    it 'deletes the issue and redirect to epic list' do
      page.accept_alert 'Epic will be removed! Are you sure?' do
        find('.detail-page-header button').click
      end

      wait_for_requests

      expect(find('.issuable-list')).not_to have_content(epic.title)
      expect(find('.issuable-list')).to have_content(epic2.title)
    end
  end
end
