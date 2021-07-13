# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown label', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:label) { create(:label, project: project, title: 'bug-label') }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_dropdown) { find('#js-dropdown-label .filter-dropdown') }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the labels when opened' do
      filtered_search.set('label:=')

      expect_filtered_search_dropdown_results(filter_dropdown, 1)
    end
  end
end
