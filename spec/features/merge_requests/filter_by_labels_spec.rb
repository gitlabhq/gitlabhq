require 'rails_helper'

feature 'Issue filtering by Labels', js: true do
  include FilteredSearchHelpers
  include MergeRequestHelpers

  let(:project) { create(:project, :public) }
  let!(:user)   { create(:user) }
  let!(:label)  { create(:label, project: project) }

  let!(:bug) { create(:label, project: project, title: 'bug') }
  let!(:feature) { create(:label, project: project, title: 'feature') }
  let!(:enhancement) { create(:label, project: project, title: 'enhancement') }

  let!(:mr1) { create(:merge_request, title: "Bugfix1", source_project: project, target_project: project, source_branch: "bugfix1") }
  let!(:mr2) { create(:merge_request, title: "Bugfix2", source_project: project, target_project: project, source_branch: "bugfix2") }
  let!(:mr3) { create(:merge_request, title: "Feature1", source_project: project, target_project: project, source_branch: "feature1") }

  before do
    mr1.labels << bug

    mr2.labels << bug
    mr2.labels << enhancement

    mr3.title = "Feature1"
    mr3.labels << feature

    project.team << [user, :master]
    sign_in(user)

    visit project_merge_requests_path(project)
  end

  context 'filter by label bug' do
    before do
      input_filtered_search('label:~bug')
    end

    it 'apply the filter' do
      expect(page).to have_content "Bugfix1"
      expect(page).to have_content "Bugfix2"
      expect(page).not_to have_content "Feature1"
    end
  end

  context 'filter by label feature' do
    before do
      input_filtered_search('label:~feature')
    end

    it 'applies the filter' do
      expect(page).to have_content "Feature1"
      expect(page).not_to have_content "Bugfix2"
      expect(page).not_to have_content "Bugfix1"
    end
  end

  context 'filter by label enhancement' do
    before do
      input_filtered_search('label:~enhancement')
    end

    it 'applies the filter' do
      expect(page).to have_content "Bugfix2"
      expect(page).not_to have_content "Feature1"
      expect(page).not_to have_content "Bugfix1"
    end
  end

  context 'filter by label enhancement and bug in issues list' do
    before do
      input_filtered_search('label:~bug label:~enhancement')
    end

    it 'applies the filters' do
      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content "Bugfix2"
      expect(page).not_to have_content "Feature1"
    end
  end

  context 'clear button' do
    before do
      input_filtered_search('label:~bug')
    end

    it 'allows user to remove filtered labels' do
      first('.clear-search').click
      filtered_search.send_keys(:enter)

      expect(page).to have_issuable_counts(open: 3, closed: 0, all: 3)
      expect(page).to have_content "Bugfix2"
      expect(page).to have_content "Feature1"
      expect(page).to have_content "Bugfix1"
    end
  end

  context 'filter dropdown' do
    it 'filters by label name' do
      init_label_search
      filtered_search.send_keys('~bug')

      page.within '.filter-dropdown' do
        expect(page).not_to have_content 'enhancement'
        expect(page).to have_content 'bug'
      end
    end
  end
end
