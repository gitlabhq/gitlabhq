# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown base', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_assignee) { '#js-dropdown-assignee' }
  let(:filter_dropdown) { find("#{js_dropdown_assignee} .filter-dropdown") }

  def dropdown_assignee_size
    filter_dropdown.all('.filter-dropdown-item').size
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'shows loading indicator when opened' do
      slow_requests do
        # We aren't using `input_filtered_search` because we want to see the loading indicator
        filtered_search.set('assignee=')

        expect(page).to have_css("#{js_dropdown_assignee} .filter-dropdown-loading", visible: true)
      end
    end

    it 'hides loading indicator when loaded' do
      input_filtered_search('assignee=', submit: false, extra_space: false)

      expect(find(js_dropdown_assignee)).not_to have_css('.filter-dropdown-loading')
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      input_filtered_search('assignee=', submit: false, extra_space: false)
      initial_size = dropdown_assignee_size

      expect(initial_size).to be > 0

      new_user = create(:user)
      project.add_maintainer(new_user)
      find('.filtered-search-box .clear-search').click
      input_filtered_search('assignee=', submit: false, extra_space: false)

      expect(dropdown_assignee_size).to eq(initial_size)
    end
  end
end
