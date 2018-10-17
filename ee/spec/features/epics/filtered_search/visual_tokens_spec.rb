require 'spec_helper'

describe 'epics list', :js do
  include FilteredSearchHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:label) { create(:group_label, group: group, title: 'bug') }
  let!(:epic) { create(:epic, group: group, start_date: 10.days.ago, due_date: 5.days.ago) }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_author_dropdown) { find("#js-dropdown-author .filter-dropdown") }
  let(:filter_label_dropdown) { find("#js-dropdown-label .filter-dropdown") }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)

    visit group_epics_path(group)
  end

  context 'editing author token' do
    before do
      input_filtered_search('author:@root', submit: false)
      first('.tokens-container .filtered-search-token').click
    end

    it 'converts keyword into visual token' do
      page.within('.tokens-container') do
        expect(page).to have_selector('.js-visual-token')
        expect(page).to have_content('Author')
      end
    end

    it 'opens author dropdown' do
      expect(page).to have_css('#js-dropdown-author', visible: true)
    end

    it 'makes value editable' do
      expect_filtered_search_input('@root')
    end

    it 'filters value' do
      filtered_search.send_keys(:backspace)

      expect(page).to have_css('#js-dropdown-author .filter-dropdown .filter-dropdown-item', count: 1)
    end
  end

  context 'editing label token' do
    before do
      input_filtered_search("label:~#{label.title}", submit: false)
      first('.tokens-container .filtered-search-token').click
    end

    it 'converts keyword into visual token' do
      page.within('.tokens-container') do
        expect(page).to have_selector('.js-visual-token')
        expect(page).to have_content('Label')
      end
    end

    it 'opens label dropdown' do
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: label.title)).to be_visible
      expect(page).to have_css('#js-dropdown-label', visible: true)
    end

    it 'makes value editable' do
      expect_filtered_search_input("~#{label.title}")
    end

    it 'filters value' do
      expect(filter_label_dropdown.find('.filter-dropdown-item', text: label.title)).to be_visible

      filtered_search.send_keys(:backspace)

      filter_label_dropdown.find('.filter-dropdown-item')

      expect(page.all('#js-dropdown-label .filter-dropdown .filter-dropdown-item').size).to eq(1)
    end
  end
end
