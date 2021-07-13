# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown milestone', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let_it_be(:uppercase_milestone) { create(:milestone, title: 'CAP_MILESTONE', project: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_dropdown) { find('#js-dropdown-milestone .filter-dropdown') }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    before do
      filtered_search.set('milestone:=')
    end

    it 'loads all the milestones when opened' do
      expect_filtered_search_dropdown_results(filter_dropdown, 2)
    end
  end
end
