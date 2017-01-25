require 'rails_helper'

describe 'Dropdown label', js: true, feature: true do
  include WaitForAjax

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user) }
  let!(:bug_label) { create(:label, project: project, title: 'bug') }
  let!(:uppercase_label) { create(:label, project: project, title: 'BUG') }
  let!(:two_words_label) { create(:label, project: project, title: 'High Priority') }
  let!(:wont_fix_label) { create(:label, project: project, title: 'Won"t Fix') }
  let!(:wont_fix_single_label) { create(:label, project: project, title: 'Won\'t Fix') }
  let!(:special_label) { create(:label, project: project, title: '!@#$%^+&*()')}
  let!(:long_label) { create(:label, project: project, title: 'this is a very long title this is a very long title this is a very long title this is a very long title this is a very long title')}
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_label) { '#js-dropdown-label' }

  def send_keys_to_filtered_search(input)
    input.split("").each do |i|
      filtered_search.send_keys(i)
      sleep 3
      wait_for_ajax
      sleep 3
    end
  end

  def dropdown_label_size
    page.all('#js-dropdown-label .filter-dropdown .filter-dropdown-item').size
  end

  def click_label(text)
    find('#js-dropdown-label .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.team << [user, :master]
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'keyboard navigation' do
    it 'selects label' do
      send_keys_to_filtered_search('label:')

      filtered_search.native.send_keys(:down, :down, :enter)

      expect(filtered_search.value).to eq("label:~#{special_label.name}")
    end
  end

  describe 'behavior' do
    it 'opens when the search bar has label:' do
      filtered_search.set('label:')

      expect(page).to have_css(js_dropdown_label, visible: true)
    end

    it 'closes when the search bar is unfocused' do
      find('body').click()

      expect(page).to have_css(js_dropdown_label, visible: false)
    end

    it 'should show loading indicator when opened' do
      filtered_search.set('label:')

      expect(page).to have_css('#js-dropdown-label .filter-dropdown-loading', visible: true)
    end

    it 'should hide loading indicator when loaded' do
      send_keys_to_filtered_search('label:')

      expect(page).not_to have_css('#js-dropdown-label .filter-dropdown-loading')
    end

    it 'should load all the labels when opened' do
      send_keys_to_filtered_search('label:')

      expect(dropdown_label_size).to be > 0
    end
  end

  describe 'filtering' do
    before do
      filtered_search.set('label')
    end

    it 'filters by name' do
      send_keys_to_filtered_search(':b')

      expect(dropdown_label_size).to eq(2)
    end

    it 'filters by case insensitive name' do
      send_keys_to_filtered_search(':B')

      expect(dropdown_label_size).to eq(2)
    end

    it 'filters by name with symbol' do
      send_keys_to_filtered_search(':~bu')

      expect(dropdown_label_size).to eq(2)
    end

    it 'filters by case insensitive name with symbol' do
      send_keys_to_filtered_search(':~BU')

      expect(dropdown_label_size).to eq(2)
    end

    it 'filters by multiple words' do
      send_keys_to_filtered_search(':Hig')

      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by multiple words with symbol' do
      send_keys_to_filtered_search(':~Hig')

      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by multiple words containing single quotes' do
      send_keys_to_filtered_search(':won\'t')

      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by multiple words containing single quotes with symbol' do
      send_keys_to_filtered_search(':~won\'t')

      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by multiple words containing double quotes' do
      send_keys_to_filtered_search(':won"t')

      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by multiple words containing double quotes with symbol' do
      send_keys_to_filtered_search(':~won"t')

      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by special characters' do
      send_keys_to_filtered_search(':^+')

      expect(dropdown_label_size).to eq(1)
    end

    it 'filters by special characters with symbol' do
      send_keys_to_filtered_search(':~^+')

      expect(dropdown_label_size).to eq(1)
    end
  end

  describe 'selecting from dropdown' do
    before do
      filtered_search.set('label:')
    end

    it 'fills in the label name when the label has not been filled' do
      click_label(bug_label.title)

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:~#{bug_label.title} ")
    end

    it 'fills in the label name when the label is partially filled' do
      send_keys_to_filtered_search('bu')
      click_label(bug_label.title)

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:~#{bug_label.title} ")
    end

    it 'fills in the label name that contains multiple words' do
      click_label(two_words_label.title)

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:~\"#{two_words_label.title}\" ")
    end

    it 'fills in the label name that contains multiple words and is very long' do
      click_label(long_label.title)

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:~\"#{long_label.title}\" ")
    end

    it 'fills in the label name that contains double quotes' do
      click_label(wont_fix_label.title)

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:~'#{wont_fix_label.title}' ")
    end

    it 'fills in the label name with the correct capitalization' do
      click_label(uppercase_label.title)

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:~#{uppercase_label.title} ")
    end

    it 'fills in the label name with special characters' do
      click_label(special_label.title)

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:~#{special_label.title} ")
    end

    it 'selects `no label`' do
      find('#js-dropdown-label .filter-dropdown-item', text: 'No Label').click

      expect(page).to have_css(js_dropdown_label, visible: false)
      expect(filtered_search.value).to eq("label:none ")
    end
  end

  describe 'input has existing content' do
    it 'opens label dropdown with existing search term' do
      filtered_search.set('searchTerm label:')
      expect(page).to have_css(js_dropdown_label, visible: true)
    end

    it 'opens label dropdown with existing author' do
      filtered_search.set('author:@person label:')
      expect(page).to have_css(js_dropdown_label, visible: true)
    end

    it 'opens label dropdown with existing assignee' do
      filtered_search.set('assignee:@person label:')
      expect(page).to have_css(js_dropdown_label, visible: true)
    end

    it 'opens label dropdown with existing label' do
      filtered_search.set('label:~urgent label:')
      expect(page).to have_css(js_dropdown_label, visible: true)
    end

    it 'opens label dropdown with existing milestone' do
      filtered_search.set('milestone:%v2.0 label:')
      expect(page).to have_css(js_dropdown_label, visible: true)
    end
  end
end
