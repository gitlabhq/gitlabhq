# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown label', :js do
  include FilteredSearchHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:filtered_search) { find('.filtered-search') }
  let(:filter_dropdown) { find('#js-dropdown-label .filter-dropdown') }

  before do
    project.add_maintainer(user)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the labels when opened' do
      create(:label, project: project, title: 'bug-label')
      filtered_search.set('label=')

      expect_filtered_search_dropdown_results(filter_dropdown, 1)
    end
  end
end
