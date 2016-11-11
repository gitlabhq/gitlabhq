require 'rails_helper'

feature 'Issue filtering by Labels', feature: true, js: true do
  include WaitForAjax

  let(:project) { create(:project, :public) }
  let!(:user)   { create(:user) }
  let!(:label)  { create(:label, project: project) }

  let!(:bug) { create(:label, project: project, title: 'bug') }
  let!(:feature) { create(:label, project: project, title: 'feature') }
  let!(:enhancement) { create(:label, project: project, title: 'enhancement') }

  let!(:mr1) { create(:merge_request, title: "Bugfix1", source_project: project, target_project: project, source_branch: "bugfix1") }
  let!(:mr2) { create(:merge_request, title:"Bugfix2", source_project: project, target_project: project, source_branch: "bugfix2") }
  let!(:mr3) { create(:merge_request, title: "Feature1", source_project: project, target_project: project, source_branch: "feature1") }

  before do
    mr1.labels << bug

    mr2.labels << bug
    mr2.labels << enhancement

    mr3.title = "Feature1"
    mr3.labels << feature

    project.team << [user, :master]
    login_as(user)

    visit namespace_project_merge_requests_path(project.namespace, project)
  end

  context 'filter by label bug' do
    before do
      select_labels('bug')
    end

    it 'apply the filter' do
      expect(page).to have_content "Bugfix1"
      expect(page).to have_content "Bugfix2"
      expect(page).not_to have_content "Feature1"
      expect(find('.filtered-labels')).to have_content "bug"
      expect(find('.filtered-labels')).not_to have_content "feature"
      expect(find('.filtered-labels')).not_to have_content "enhancement"

      find('.js-label-filter-remove').click
      wait_for_ajax
      expect(find('.filtered-labels', visible: false)).to have_no_content "bug"
    end
  end

  context 'filter by label feature' do
    before do
      select_labels('feature')
    end

    it 'applies the filter' do
      expect(page).to have_content "Feature1"
      expect(page).not_to have_content "Bugfix2"
      expect(page).not_to have_content "Bugfix1"
      expect(find('.filtered-labels')).to have_content "feature"
      expect(find('.filtered-labels')).not_to have_content "bug"
      expect(find('.filtered-labels')).not_to have_content "enhancement"
    end
  end

  context 'filter by label enhancement' do
    before do
      select_labels('enhancement')
    end

    it 'applies the filter' do
      expect(page).to have_content "Bugfix2"
      expect(page).not_to have_content "Feature1"
      expect(page).not_to have_content "Bugfix1"
      expect(find('.filtered-labels')).to have_content "enhancement"
      expect(find('.filtered-labels')).not_to have_content "bug"
      expect(find('.filtered-labels')).not_to have_content "feature"
    end
  end

  context 'filter by label enhancement and bug in issues list' do
    before do
      select_labels('bug', 'enhancement')
    end

    it 'applies the filters' do
      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content "Bugfix2"
      expect(page).not_to have_content "Feature1"
      expect(find('.filtered-labels')).to have_content "bug"
      expect(find('.filtered-labels')).to have_content "enhancement"
      expect(find('.filtered-labels')).not_to have_content "feature"

      find('.js-label-filter-remove', match: :first).click
      wait_for_ajax

      expect(page).to have_content "Bugfix2"
      expect(page).not_to have_content "Feature1"
      expect(page).not_to have_content "Bugfix1"
      expect(find('.filtered-labels')).not_to have_content "bug"
      expect(find('.filtered-labels')).to have_content "enhancement"
      expect(find('.filtered-labels')).not_to have_content "feature"
    end
  end

  context 'remove filtered labels' do
    before do
      page.within '.labels-filter' do
        click_button 'Label'
        wait_for_ajax
        click_link 'bug'
        find('.dropdown-menu-close').click
      end

      page.within '.filtered-labels' do
        expect(page).to have_content 'bug'
      end
    end

    it 'allows user to remove filtered labels' do
      first('.js-label-filter-remove').click
      wait_for_ajax

      expect(find('.filtered-labels', visible: false)).not_to have_content 'bug'
      expect(find('.labels-filter')).not_to have_content 'bug'
    end
  end

  context 'dropdown filtering' do
    it 'filters by label name' do
      page.within '.labels-filter' do
        click_button 'Label'
        wait_for_ajax
        find('.dropdown-input input').set 'bug'

        page.within '.dropdown-content' do
          expect(page).not_to have_content 'enhancement'
          expect(page).to have_content 'bug'
        end
      end
    end
  end

  def select_labels(*labels)
    page.find('.js-label-select').click
    wait_for_ajax
    labels.each do |label|
      execute_script("$('.dropdown-menu-labels li:contains(\"#{label}\") a').click()")
    end
    page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
    wait_for_ajax
  end
end
