require 'spec_helper'

describe 'epics list', :js do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when epics exist for the group' do
    let!(:epic1) { create(:epic, group: group, end_date: 10.days.ago) }
    let!(:epic2) { create(:epic, group: group, start_date: 2.days.ago) }
    let!(:epic3) { create(:epic, group: group, start_date: 10.days.ago, end_date: 5.days.ago) }

    before do
      visit group_epics_path(group)
    end

    it 'shows the epics in the navigation sidebar' do
      expect(first('.nav-sidebar  .active a .nav-item-name')).to have_content('Epics')
      expect(first('.nav-sidebar .active a .count')).to have_content('3')
    end

    it 'renders the filtered search bar correctly' do
      page.within('.content-wrapper .content') do
        expect(page).to have_css('.epics-filters')
      end
    end

    it 'sorts by end_date ASC by default' do
      expect(page).to have_button('Planned finish date')

      page.within('.content-wrapper .content') do
        expect(find('.top-area')).to have_content('All 3')

        page.within(".issuable-list") do
          page.within("li:nth-child(1)") do
            expect(page).to have_content(epic1.title)
          end

          page.within("li:nth-child(2)") do
            expect(page).to have_content(epic3.title)
          end

          page.within("li:nth-child(3)") do
            expect(page).to have_content(epic2.title)
          end
        end
      end
    end

    it 'sorts by the selected value and stores the selection for epic list & roadmap' do
      page.within('.epics-other-filters') do
        click_button 'Planned finish date'
        sort_options = find('ul.dropdown-menu-sort li').all('a').collect(&:text)

        expect(sort_options[0]).to eq('Created date')
        expect(sort_options[1]).to eq('Last updated')
        expect(sort_options[2]).to eq('Planned start date')
        expect(sort_options[3]).to eq('Planned finish date')

        click_link 'Planned start date'
      end

      expect(page).to have_button('Planned start date')

      page.within('.content-wrapper .content') do
        expect(find('.top-area')).to have_content('All 3')

        page.within(".issuable-list") do
          page.within("li:nth-child(1)") do
            expect(page).to have_content(epic3.title)
          end

          page.within("li:nth-child(2)") do
            expect(page).to have_content(epic2.title)
          end

          page.within("li:nth-child(3)") do
            expect(page).to have_content(epic1.title)
          end
        end
      end

      visit group_epics_path(group)

      expect(page).to have_button('Planned start date')

      visit group_roadmap_path(group)

      expect(page).to have_button('Planned start date')
    end

    it 'renders the epic detail correctly after clicking the link' do
      page.within('.content-wrapper .content .issuable-list') do
        click_link(epic1.title)
      end

      wait_for_requests

      expect(page.find('.issuable-details h2.title')).to have_content(epic1.title)
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
