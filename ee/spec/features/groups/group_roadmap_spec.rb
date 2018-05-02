require 'spec_helper'

describe 'group epic roadmap', :js do
  include FilteredSearchHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_label) { '#js-dropdown-label' }
  let(:filter_dropdown) { find("#{js_dropdown_label} .filter-dropdown") }

  let(:bug_label) { create(:group_label, group: group, title: 'Bug') }
  let(:critical_label) { create(:group_label, group: group, title: 'Critical') }

  def search_for_label(label)
    init_label_search
    filter_dropdown.find('.filter-dropdown-item', text: bug_label.title).click
    filtered_search.send_keys(:enter)
  end

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when epics exist for the group' do
    let!(:epic_with_bug) { create(:labeled_epic, group: group, start_date: 10.days.ago, end_date: 1.day.ago, labels: [bug_label]) }
    let!(:epic_with_critical) { create(:labeled_epic, group: group, start_date: 20.days.ago, end_date: 2.days.ago, labels: [critical_label]) }

    before do
      visit group_roadmap_path(group)
      wait_for_requests
    end

    describe 'roadmap page' do
      it 'renders the filtered search bar correctly' do
        page.within('.content-wrapper .content') do
          expect(page).to have_css('.epics-filters')
        end
      end

      it 'renders roadmap view' do
        page.within('.content-wrapper .content') do
          expect(page).to have_css('.roadmap-container')
        end
      end

      it 'renders all group epics within roadmap' do
        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 2)
        end
      end
    end

    describe 'roadmap page with filter applied' do
      before do
        search_for_label(bug_label)
      end

      it 'renders filtered search bar with applied filter token' do
        expect_tokens([label_token(bug_label.title)])
      end

      it 'renders roadmap view with matching epic' do
        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 1)
          expect(page).to have_content(epic_with_bug.title)
        end
      end
    end
  end

  context 'when no epics exist for the group' do
    before do
      visit group_roadmap_path(group)
    end

    describe 'roadmap page' do
      it 'does not render the filtered search bar' do
        page.within('.content-wrapper .content') do
          expect(page).not_to have_css('.epics-filters')
        end
      end
    end
  end
end
