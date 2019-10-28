# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown release', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project, :repository) }
  let!(:user) { create(:user) }
  let!(:release) { create(:release, tag: 'v1.0', project: project) }
  let!(:crazy_release) { create(:release, tag: '☺!/"#%&\'{}+,-.<>;=@]_`{|}🚀', project: project) }

  def filtered_search
    find('.filtered-search')
  end

  def filter_dropdown
    find('#js-dropdown-release .filter-dropdown')
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    before do
      filtered_search.set('release:')
    end

    def expect_results(count)
      expect(filter_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: count)
    end

    it 'loads all the releases when opened' do
      expect_results(2)
    end

    it 'filters by tag name' do
      filtered_search.send_keys("☺")
      expect_results(1)
    end

    it 'fills in the release name when the autocomplete hint is clicked' do
      find('#js-dropdown-release .filter-dropdown-item', text: crazy_release.tag).click

      expect(page).to have_css('#js-dropdown-release', visible: false)
      expect_tokens([release_token(crazy_release.tag)])
      expect_filtered_search_input_empty
    end
  end
end
