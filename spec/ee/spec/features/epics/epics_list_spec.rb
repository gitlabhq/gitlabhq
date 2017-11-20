require 'spec_helper'

describe 'epics list', :js do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when epics exist for the group' do
    let!(:epics) { create_list(:epic, 2, group: group) }

    before do
      visit group_epics_path(group)
    end

    it 'shows the epics in the navigation sidebar' do
      expect(first('.nav-sidebar  .active a .nav-item-name')).to have_content('Epics')
      expect(first('.nav-sidebar .active a .count')).to have_content('2')
    end

    it 'renders the list correctly' do
      page.within('.page-with-new-nav .content') do
        expect(find('.top-area')).to have_content('All 2')
        within('.issuable-list') do
          expect(page).to have_content(epics.first.title)
          expect(page).to have_content(epics.second.title)
        end
      end
    end

    it 'renders the epic detail correctly after clicking the link' do
      page.within('.page-with-new-nav .content .issuable-list') do
        click_link(epics.first.title)
      end

      wait_for_requests

      expect(page.find('.issuable-details h2.title')).to have_content(epics.first.title)
    end
  end

  context 'when no epics exist for the group' do
    it 'renders the empty list page' do
      visit group_epics_path(group)

      within('#content-body') do
        expect(find('.empty-state h4'))
          .to have_content('Epics let you manage your portfolio of projects more efficiently and with less effort')
      end
    end
  end
end
