require 'rails_helper'

describe 'Dropdown milestone', js: true, feature: true do
  include WaitForAjax

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user) }
  let!(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let!(:uppercase_milestone) { create(:milestone, title: 'CAP_MILESTONE', project: project) }
  let!(:two_words_milestone) { create(:milestone, title: 'Future Plan', project: project) }
  let!(:wont_fix_milestone) { create(:milestone, title: 'Won"t Fix', project: project) }
  let!(:special_milestone) { create(:milestone, title: '!@#$%^&*(+)', project: project) }
  let!(:long_milestone) { create(:milestone, title: 'this is a very long title this is a very long title this is a very long title this is a very long title this is a very long title', project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_milestone) { '#js-dropdown-milestone' }

  def send_keys_to_filtered_search(input)
    input.split("").each do |i|
      filtered_search.send_keys(i)
      sleep 3
      wait_for_ajax
      sleep 3
    end
  end

  def dropdown_milestone_size
    page.all('#js-dropdown-milestone .filter-dropdown .filter-dropdown-item').size
  end

  def click_milestone(text)
    find('#js-dropdown-milestone .filter-dropdown .filter-dropdown-item', text: text).click
  end

  def click_static_milestone(text)
    find('#js-dropdown-milestone .filter-dropdown-item', text: text).click
  end

  before do
    project.team << [user, :master]
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
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
      filtered_search.set('milestone:')

      expect(page).to have_css('#js-dropdown-milestone .filter-dropdown-loading', visible: true)
    end

    it 'should hide loading indicator when loaded' do
      send_keys_to_filtered_search('milestone:')

      expect(page).not_to have_css('#js-dropdown-milestone .filter-dropdown-loading')
    end

    it 'should load all the milestones when opened' do
      send_keys_to_filtered_search('milestone:')

      expect(dropdown_milestone_size).to be > 0
    end
  end

  describe 'filtering' do
    before do
      filtered_search.set('milestone')
    end

    it 'filters by name' do
      send_keys_to_filtered_search(':v1')

      expect(dropdown_milestone_size).to eq(1)
    end

    it 'filters by case insensitive name' do
      send_keys_to_filtered_search(':V1')

      expect(dropdown_milestone_size).to eq(1)
    end

    it 'filters by name with symbol' do
      send_keys_to_filtered_search(':%v1')

      expect(dropdown_milestone_size).to eq(1)
    end

    it 'filters by case insensitive name with symbol' do
      send_keys_to_filtered_search(':%V1')

      expect(dropdown_milestone_size).to eq(1)
    end

    it 'filters by special characters' do
      send_keys_to_filtered_search(':(+')

      expect(dropdown_milestone_size).to eq(1)
    end

    it 'filters by special characters with symbol' do
      send_keys_to_filtered_search(':%(+')

      expect(dropdown_milestone_size).to eq(1)
    end
  end

  describe 'selecting from dropdown' do
    before do
      filtered_search.set('milestone:')
    end

    it 'fills in the milestone name when the milestone has not been filled' do
      click_milestone(milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:%#{milestone.title} ")
    end

    it 'fills in the milestone name when the milestone is partially filled' do
      send_keys_to_filtered_search('v')
      click_milestone(milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:%#{milestone.title} ")
    end

    it 'fills in the milestone name that contains multiple words' do
      click_milestone(two_words_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:%\"#{two_words_milestone.title}\" ")
    end

    it 'fills in the milestone name that contains multiple words and is very long' do
      click_milestone(long_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:%\"#{long_milestone.title}\" ")
    end

    it 'fills in the milestone name that contains double quotes' do
      click_milestone(wont_fix_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:%'#{wont_fix_milestone.title}' ")
    end

    it 'fills in the milestone name with the correct capitalization' do
      click_milestone(uppercase_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:%#{uppercase_milestone.title} ")
    end

    it 'fills in the milestone name with special characters' do
      click_milestone(special_milestone.title)

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:%#{special_milestone.title} ")
    end

    it 'selects `no milestone`' do
      click_static_milestone('No Milestone')

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:none ")
    end

    it 'selects `upcoming milestone`' do
      click_static_milestone('Upcoming')

      expect(page).to have_css(js_dropdown_milestone, visible: false)
      expect(filtered_search.value).to eq("milestone:upcoming ")
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
  end
end
