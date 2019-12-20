# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown release', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project, :repository) }
  let!(:user) { create(:user) }
  let!(:release) { create(:release, tag: 'v1.0', project: project) }
  let!(:crazy_release) { create(:release, tag: '☺!/"#%&\'{}+,-.<>;=@]_`{|}🚀', project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_dropdown) { find('#js-dropdown-release .filter-dropdown') }

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

    it 'loads all the releases when opened' do
      expect_filtered_search_dropdown_results(filter_dropdown, 2)
    end
  end
end
