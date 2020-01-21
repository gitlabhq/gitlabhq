# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown milestone', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user) }
  let!(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let!(:uppercase_milestone) { create(:milestone, title: 'CAP_MILESTONE', project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:filter_dropdown) { find('#js-dropdown-milestone .filter-dropdown') }

  before do
    project.add_maintainer(user)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    before do
      filtered_search.set('milestone=')
    end

    it 'loads all the milestones when opened' do
      expect_filtered_search_dropdown_results(filter_dropdown, 2)
    end
  end
end
