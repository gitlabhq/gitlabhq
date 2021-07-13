# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown release', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:release) { create(:release, tag: 'v1.0', project: project) }
  let_it_be(:crazy_release) { create(:release, tag: '☺!/"#%&\'{}+,-.<>;=@]_`{|}🚀', project: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_dropdown) { find('#js-dropdown-release .filter-dropdown') }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    before do
      filtered_search.set('release:=')
    end

    it 'loads all the releases when opened' do
      expect_filtered_search_dropdown_results(filter_dropdown, 2)
    end
  end
end
