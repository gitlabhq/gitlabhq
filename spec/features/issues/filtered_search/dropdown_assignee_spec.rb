require 'rails_helper'

describe 'Dropdown assignee', :feature, :js do
  include FilteredSearchHelpers

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let!(:user_john) { create(:user, name: 'John', username: 'th0mas') }
  let!(:user_jacob) { create(:user, name: 'Jacob', username: 'otter32') }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_assignee) { '#js-dropdown-assignee' }
  let(:filter_dropdown) { find("#{js_dropdown_assignee} .filter-dropdown") }

  def dropdown_assignee_size
    filter_dropdown.all('.filter-dropdown-item').size
  end

  def click_assignee(text)
    find('#js-dropdown-assignee .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.team << [user, :master]
    project.team << [user_john, :master]
    project.team << [user_jacob, :master]
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'filtering' do
    before do
      filtered_search.set('assignee:')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_john.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
    end

    it 'filters by name' do
      filtered_search.send_keys('j')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_john.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user.name)
    end

    it 'filters by case insensitive name' do
      filtered_search.send_keys('J')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_john.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user.name)
    end

    it 'filters by username with symbol' do
      filtered_search.send_keys('@ot')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by case insensitive username with symbol' do
      filtered_search.send_keys('@OT')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by username without symbol' do
      filtered_search.send_keys('ot')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by case insensitive username without symbol' do
      filtered_search.send_keys('OT')

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      filtered_search.set('assignee')
      filtered_search.send_keys(':')
      initial_size = dropdown_assignee_size

      expect(initial_size).to be > 0

      new_user = create(:user)
      project.team << [new_user, :master]
      find('.filtered-search-box .clear-search').click
      filtered_search.set('assignee')
      filtered_search.send_keys(':')

      expect(dropdown_assignee_size).to eq(initial_size)
    end
  end
end
