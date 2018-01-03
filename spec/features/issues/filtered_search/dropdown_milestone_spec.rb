require 'rails_helper'

describe 'Dropdown milestone', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user) }
  let!(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let!(:uppercase_milestone) { create(:milestone, title: 'CAP_MILESTONE', project: project) }
  let!(:two_words_milestone) { create(:milestone, title: 'Future Plan', project: project) }
  let!(:wont_fix_milestone) { create(:milestone, title: 'Won"t Fix', project: project) }
  let!(:special_milestone) { create(:milestone, title: '!@#$%^&*(+)', project: project) }
  let!(:long_milestone) { create(:milestone, title: 'this is a very long title this is a very long title this is a very long title this is a very long title this is a very long title', project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_milestone) { '#js-dropdown-milestone' }
  let(:filter_dropdown) { find("#{js_dropdown_milestone} .filter-dropdown") }

  def dropdown_milestone_size
    filter_dropdown.all('.filter-dropdown-item').size
  end

  def click_milestone(text)
    find('#js-dropdown-milestone .filter-dropdown .filter-dropdown-item', text: text).click
  end

  def click_static_milestone(text)
    find('#js-dropdown-milestone .filter-dropdown-item', text: text).click
  end

  before do
    project.add_master(user)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'opens when the search bar has milestone:' do
      filtered_search.set('milestone:')

      expect(page).to have_css(js_dropdown_milestone, visible: true)
    end

    it 'closes when the search bar is unfocused' do
      find('body').click()

      expect(page).to have_css(js_dropdown_milestone, visible: false)
    end

    it 'should show loading indicator when opened' do
      slow_requests do
        filtered_search.set('milestone:')

        expect(page).to have_css('#js-dropdown-milestone .filter-dropdown-loading', visible: true)
      end
    end

    it 'should hide loading indicator when loaded' do
      filtered_search.set('milestone:')

      expect(find(js_dropdown_milestone)).not_to have_css('.filter-dropdown-loading')
    end

    it 'should load all the milestones when opened' do
      filtered_search.set('milestone:')

      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 6)
    end
  end

  describe 'filtering' do
    before do
      filtered_search.set('milestone:')

      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(uppercase_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(two_words_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(wont_fix_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(special_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(long_milestone.title)
    end

    it 'filters by name' do
      filtered_search.send_keys('v1')

      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'filters by case insensitive name' do
      filtered_search.send_keys('V1')

      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'filters by name with symbol' do
      filtered_search.send_keys('%v1')

      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'filters by case insensitive name with symbol' do
      filtered_search.send_keys('%V1')

      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'filters by special characters' do
      filtered_search.send_keys('(+')

      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)
    end

    it 'filters by special characters with symbol' do
      filtered_search.send_keys('%(+')

      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)
    end
  end

  describe 'selecting from dropdown' do
    before do
      filtered_search.set('milestone:')

      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(uppercase_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(two_words_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(wont_fix_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(special_milestone.title)
      expect(find("#{js_dropdown_milestone} .filter-dropdown")).to have_content(long_milestone.title)
    end

    it 'fills in the milestone name when the milestone has not been filled' do
      click_milestone(milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token(milestone.title)])
      expect_filtered_search_input_empty
    end

    it 'fills in the milestone name when the milestone is partially filled' do
      filtered_search.send_keys('v')
      click_milestone(milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token(milestone.title)])
      expect_filtered_search_input_empty
    end

    it 'fills in the milestone name that contains multiple words' do
      click_milestone(two_words_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token("\"#{two_words_milestone.title}\"")])
      expect_filtered_search_input_empty
    end

    it 'fills in the milestone name that contains multiple words and is very long' do
      click_milestone(long_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token("\"#{long_milestone.title}\"")])
      expect_filtered_search_input_empty
    end

    it 'fills in the milestone name that contains double quotes' do
      click_milestone(wont_fix_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token("'#{wont_fix_milestone.title}'")])
      expect_filtered_search_input_empty
    end

    it 'fills in the milestone name with the correct capitalization' do
      click_milestone(uppercase_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token(uppercase_milestone.title)])
      expect_filtered_search_input_empty
    end

    it 'fills in the milestone name with special characters' do
      click_milestone(special_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token(special_milestone.title)])
      expect_filtered_search_input_empty
    end

    it 'selects `no milestone`' do
      click_static_milestone('No Milestone')

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token('none', false)])
      expect_filtered_search_input_empty
    end

    it 'selects `upcoming milestone`' do
      click_static_milestone('Upcoming')

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token('upcoming', false)])
      expect_filtered_search_input_empty
    end

    it 'selects `started milestones`' do
      click_static_milestone('Started')

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect_tokens([milestone_token('started', false)])
      expect_filtered_search_input_empty
    end
  end

  describe 'input has existing content' do
    it 'opens milestone dropdown with existing search term' do
      filtered_search.set('searchTerm milestone:')

      expect(page).to have_css(js_dropdown_milestone, visible: true)
    end

    it 'opens milestone dropdown with existing author' do
      filtered_search.set('author:@john milestone:')

      expect(page).to have_css(js_dropdown_milestone, visible: true)
    end

    it 'opens milestone dropdown with existing assignee' do
      filtered_search.set('assignee:@john milestone:')

      expect(page).to have_css(js_dropdown_milestone, visible: true)
    end

    it 'opens milestone dropdown with existing label' do
      filtered_search.set('label:~important milestone:')

      expect(page).to have_css(js_dropdown_milestone, visible: true)
    end

    it 'opens milestone dropdown with existing milestone' do
      filtered_search.set('milestone:%100 milestone:')

      expect(page).to have_css(js_dropdown_milestone, visible: true)
    end

    it 'opens milestone dropdown with existing my-reaction' do
      filtered_search.set('my-reaction:star milestone:')

      expect(page).to have_css(js_dropdown_milestone, visible: true)
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      filtered_search.set('milestone:')
      initial_size = dropdown_milestone_size

      expect(initial_size).to be > 0

      create(:milestone, project: project)
      find('.filtered-search-box .clear-search').click
      filtered_search.set('milestone:')

      expect(dropdown_milestone_size).to eq(initial_size)
    end
  end
end
