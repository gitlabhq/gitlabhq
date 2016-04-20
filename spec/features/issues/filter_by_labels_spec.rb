require 'rails_helper'

feature 'Issue filtering by Labels', feature: true do
  let(:project) { create(:project, :public) }
  let!(:user)   { create(:user)}
  let!(:label)  { create(:label, project: project) }

  before do
    ['bug', 'feature', 'enhancement'].each do |title|
      create(:label,
             project: project,
             title: title)
    end

    issue1 = create(:issue, title: "Bugfix1", project: project)
    issue1.labels << project.labels.find_by(title: 'bug')

    issue2 = create(:issue, title: "Bugfix2", project: project)
    issue2.labels << project.labels.find_by(title: 'bug')
    issue2.labels << project.labels.find_by(title: 'enhancement')

    issue3 = create(:issue, title: "Feature1", project: project)
    issue3.labels << project.labels.find_by(title: 'feature')

    project.team << [user, :master]
    login_as(user)

    visit namespace_project_issues_path(project.namespace, project)
  end

  context 'filter by label bug', js: true do
    before do
      page.find('.js-label-select').click
      sleep 0.5
      execute_script("$('.dropdown-menu-labels li:contains(\"bug\") a').click()")
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      sleep 2
    end

    it 'should show issue "Bugfix1" and "Bugfix2" in issues list' do
      expect(page).to have_content "Bugfix1"
      expect(page).to have_content "Bugfix2"
    end

    it 'should not show "Feature1" in issues list' do
      expect(page).not_to have_content "Feature1"
    end

    it 'should show label "bug" in filtered-labels' do
      expect(find('.filtered-labels')).to have_content "bug"
    end

    it 'should not show label "feature" and "enhancement" in filtered-labels' do
      expect(find('.filtered-labels')).not_to have_content "feature"
      expect(find('.filtered-labels')).not_to have_content "enhancement"
    end
  end

  context 'filter by label feature', js: true do
    before do
      page.find('.js-label-select').click
      sleep 0.5
      execute_script("$('.dropdown-menu-labels li:contains(\"feature\") a').click()")
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      sleep 2
    end

    it 'should show issue "Feature1" in issues list' do
      expect(page).to have_content "Feature1"
    end

    it 'should not show "Bugfix1" and "Bugfix2" in issues list' do
      expect(page).not_to have_content "Bugfix2"
      expect(page).not_to have_content "Bugfix1"
    end

    it 'should show label "feature" in filtered-labels' do
      expect(find('.filtered-labels')).to have_content "feature"
    end

    it 'should not show label "bug" and "enhancement" in filtered-labels' do
      expect(find('.filtered-labels')).not_to have_content "bug"
      expect(find('.filtered-labels')).not_to have_content "enhancement"
    end
  end

  context 'filter by label enhancement', js: true do
    before do
      page.find('.js-label-select').click
      sleep 0.5
      execute_script("$('.dropdown-menu-labels li:contains(\"enhancement\") a').click()")
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      sleep 2
    end

    it 'should show issue "Bugfix2" in issues list' do
      expect(page).to have_content "Bugfix2"
    end

    it 'should not show "Feature1" and "Bugfix1" in issues list' do
      expect(page).not_to have_content "Feature1"
      expect(page).not_to have_content "Bugfix1"
    end

    it 'should show label "enhancement" in filtered-labels' do
      expect(find('.filtered-labels')).to have_content "enhancement"
    end

    it 'should not show label "feature" and "bug" in filtered-labels' do
      expect(find('.filtered-labels')).not_to have_content "bug"
      expect(find('.filtered-labels')).not_to have_content "feature"
    end
  end

  context 'filter by label enhancement or feature', js: true do
    before do
      page.find('.js-label-select').click
      sleep 0.5
      execute_script("$('.dropdown-menu-labels li:contains(\"enhancement\") a').click()")
      execute_script("$('.dropdown-menu-labels li:contains(\"feature\") a').click()")
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      sleep 2
    end

    it 'should show issue "Bugfix2" or "Feature1" in issues list' do
      expect(page).to have_content "Bugfix2"
      expect(page).to have_content "Feature1"
    end

    it 'should not show "Bugfix1" in issues list' do
      expect(page).not_to have_content "Bugfix1"
    end

    it 'should show label "enhancement" and "feature" in filtered-labels' do
      expect(find('.filtered-labels')).to have_content "enhancement"
      expect(find('.filtered-labels')).to have_content "feature"
    end

    it 'should not show label "bug" in filtered-labels' do
      expect(find('.filtered-labels')).not_to have_content "bug"
    end
  end

  context 'filter by label enhancement or bug in issues list', js: true do
    before do
      page.find('.js-label-select').click
      sleep 0.5
      execute_script("$('.dropdown-menu-labels li:contains(\"enhancement\") a').click()")
      execute_script("$('.dropdown-menu-labels li:contains(\"bug\") a').click()")
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      sleep 2
    end

    it 'should show issue "Bugfix2" or "Bugfix1" in issues list' do
      expect(page).to have_content "Bugfix2"
      expect(page).to have_content "Bugfix1"
    end

    it 'should not show "Feature1"' do
      expect(page).not_to have_content "Feature1"
    end

    it 'should show label "bug" and "enhancement" in filtered-labels' do
      expect(find('.filtered-labels')).to have_content "bug"
      expect(find('.filtered-labels')).to have_content "enhancement"
    end

    it 'should not show label "feature" in filtered-labels' do
      expect(find('.filtered-labels')).not_to have_content "feature"
    end
  end
end
