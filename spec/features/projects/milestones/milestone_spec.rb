# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project milestone', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, project: project) }
  let(:active_tab_selector) { '[role="tab"][aria-selected="true"]' }

  def toggle_sidebar
    find('.milestone-sidebar .gutter-toggle').click
  end

  def sidebar_release_block
    find_by_testid('milestone-sidebar-releases')
  end

  def sidebar_release_block_collapsed_icon
    find_by_testid('milestone-sidebar-releases-collapsed-icon')
  end

  before do
    sign_in(user)
  end

  context 'when project has enabled issues' do
    before do
      visit project_milestone_path(project, milestone)
    end

    it 'shows issues tab' do
      within('#content-body') do
        expect(page).to have_link 'Issues', href: '#tab-issues'
        expect(page).to have_selector active_tab_selector, count: 1
        expect(find(active_tab_selector)).to have_content 'Issues'
        expect(page).to have_text('Unstarted Issues')
      end
    end

    it 'shows issues stats' do
      expect(find('.milestone-sidebar')).to have_content 'Issues 0'
    end

    it 'shows link to browse and add issues' do
      within('.milestone-sidebar') do
        expect(page).to have_link 'New issue'
        expect(page).to have_link 'Open: 0'
        expect(page).to have_link 'Closed: 0'
      end
    end
  end

  context 'when clicking on other tabs' do
    using RSpec::Parameterized::TableSyntax

    where(:tab_text, :href, :panel_content) do
      'Merge requests' | '#tab-merge-requests' | 'Work in progress'
      'Participants'   | '#tab-participants'   | nil
      'Labels'         | '#tab-labels'         | nil
    end

    with_them do
      before do
        visit project_milestone_path(project, milestone)
        click_link(tab_text, href: href)
      end

      it 'shows the merge requests tab and panel' do
        within('#content-body') do
          expect(find(active_tab_selector)).to have_content tab_text
          expect(find(href)).to be_visible
          expect(page).to have_text(panel_content) if panel_content
        end
      end

      it 'sets the location hash' do
        expect(current_url).to end_with(href)
      end
    end
  end

  context 'when project has disabled issues' do
    before do
      create(:issue, project: project, milestone: milestone)
      project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)

      visit project_milestone_path(project, milestone)
    end

    it 'does not show any issues under the issues tab' do
      within('#content-body') do
        expect(find(active_tab_selector)).to have_content 'Issues'
        expect(page).not_to have_selector '.issuable-row'
      end
    end

    it 'hides issues stats' do
      expect(find('.milestone-sidebar')).not_to have_content 'Issues 0'
    end

    it 'hides new issue button' do
      within('.milestone-sidebar') do
        expect(page).not_to have_link 'New issue'
      end
    end

    it 'does not show an informative message' do
      expect(page).not_to have_content('Assign some issues to this milestone.')
    end
  end

  context 'when project has an issue' do
    before do
      create(:issue, project: project, milestone: milestone)

      visit project_milestone_path(project, milestone)
    end

    describe 'the collapsed sidebar' do
      before do
        toggle_sidebar
      end

      it 'shows the total MR and issue counts' do
        find('.milestone-sidebar .block', match: :first)

        aggregate_failures 'MR and issue blocks' do
          expect(find('.milestone-sidebar .block.issues')).to have_content '1'
          expect(find('.milestone-sidebar .block.merge-requests')).to have_content '0'
        end
      end
    end
  end

  context 'when the milestone is not associated with a release' do
    before do
      visit project_milestone_path(project, milestone)
    end

    it 'shows "None" in the "Releases" section' do
      expect(sidebar_release_block).to have_content 'Releases None'
    end

    describe 'when the sidebar is collapsed' do
      before do
        toggle_sidebar
      end

      it 'shows "0" in the "Releases" section' do
        expect(sidebar_release_block).to have_content '0'
      end

      it 'has a tooltip that reads "Releases"' do
        expect(sidebar_release_block_collapsed_icon['title']).to eq 'Releases'
      end
    end
  end

  context 'when the milestone is associated with one release' do
    before do
      create(:release, project: project, name: 'Version 5', milestones: [milestone])

      visit project_milestone_path(project, milestone)
    end

    it 'shows "Version 5" in the "Release" section' do
      expect(sidebar_release_block).to have_content 'Release Version 5'
    end

    describe 'when the sidebar is collapsed' do
      before do
        toggle_sidebar
      end

      it 'shows "1" in the "Releases" section' do
        expect(sidebar_release_block).to have_content '1'
      end

      it 'has a tooltip that reads "1 release"' do
        expect(sidebar_release_block_collapsed_icon['title']).to eq '1 release'
      end
    end
  end

  context 'when the milestone is associated with multiple releases' do
    before do
      (5..10).each do |num|
        released_at = Time.zone.parse('2019-10-04') + num.months
        create(:release, project: project, name: "Version #{num}", milestones: [milestone], released_at: released_at)
      end

      visit project_milestone_path(project, milestone)
    end

    it 'shows a shortened list of releases in the "Releases" section' do
      expect(sidebar_release_block).to have_content 'Releases Version 10 • Version 9 • Version 8 • 3 more releases'
    end

    describe 'when the sidebar is collapsed' do
      before do
        toggle_sidebar
      end

      it 'shows "6" in the "Releases" section' do
        expect(sidebar_release_block).to have_content '6'
      end

      it 'has a tooltip that reads "6 releases"' do
        expect(sidebar_release_block_collapsed_icon['title']).to eq '6 releases'
      end
    end
  end
end
