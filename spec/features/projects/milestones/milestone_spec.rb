# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project milestone', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, project: project) }
  let(:active_tab_selector) { '[role="tab"][aria-selected="true"]' }

  # Visits the milestone page and ensures the sidebar is in the desired state.
  #
  # The right sidebar may be auto-collapsed by JS after page load (either by
  # `initRightSidebar` in main.js or by the `sidebarToggleClicked` handler
  # being triggered during initialization). We wait up to 1s for any such
  # auto-collapse to occur, then force the sidebar into the desired state via
  # JavaScript so assertions run against a known, stable layout.
  def visit_milestone(collapsed: false)
    visit project_milestone_path(project, milestone)

    # Wait up to 1s to detect any post-load auto-collapse (initRightSidebar
    # fires after ~300ms). This also serves as synchronisation before we force
    # the final state below.
    page.has_css?('aside.right-sidebar.right-sidebar-collapsed', wait: 1)

    # Force the sidebar into the desired state regardless of what JS did.
    execute_script(<<~JS)
      const sidebar = document.querySelector('aside.right-sidebar');
      const layoutPage = document.querySelector('.layout-page');
      const isCollapsed = #{collapsed};
      if (sidebar) {
        sidebar.classList.toggle('right-sidebar-collapsed', isCollapsed);
        sidebar.classList.toggle('right-sidebar-expanded', !isCollapsed);
      }
      if (layoutPage) {
        layoutPage.classList.toggle('right-sidebar-collapsed', isCollapsed);
        layoutPage.classList.toggle('right-sidebar-expanded', !isCollapsed);
      }
    JS
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
      visit_milestone
    end

    it 'shows work items tab' do
      within('#content-body') do
        expect(page).to have_link 'Work items', href: '#tab-issues'
        expect(page).to have_selector active_tab_selector, count: 1
        expect(find(active_tab_selector)).to have_content 'Work items'
      end
    end

    it 'shows Work item stats' do
      expect(find('.milestone-sidebar')).to have_content 'Work items 0'
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
        visit_milestone
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

      visit_milestone
    end

    it 'does not show any work items under the work items tab' do
      within('#content-body') do
        expect(find(active_tab_selector)).to have_content 'Work items'
        expect(page).not_to have_selector '.issuable-row'
      end
    end

    it 'hides work items stats' do
      expect(find('.milestone-sidebar')).not_to have_content 'Work items 0'
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
    describe 'the collapsed sidebar' do
      before do
        create(:issue, project: project, milestone: milestone)
        visit_milestone(collapsed: true)
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
    context 'with the sidebar collapsed' do
      before do
        visit_milestone(collapsed: true)
      end

      it 'shows "0" in the "Releases" section' do
        expect(sidebar_release_block).to have_content '0'
      end

      it 'has a tooltip that reads "Releases"' do
        expect(sidebar_release_block_collapsed_icon['title']).to eq 'Releases'
      end
    end

    context 'with the sidebar expanded' do
      before do
        visit_milestone
      end

      it 'shows "None" in the "Releases" section' do
        expect(sidebar_release_block).to have_content 'Releases None'
      end
    end
  end

  context 'when the milestone is associated with one release' do
    before do
      create(:release, project: project, name: 'Version 5', milestones: [milestone])
    end

    context 'with the sidebar collapsed' do
      before do
        visit_milestone(collapsed: true)
      end

      it 'shows "1" in the "Releases" section' do
        expect(sidebar_release_block).to have_content '1'
      end

      it 'has a tooltip that reads "1 release"' do
        expect(sidebar_release_block_collapsed_icon['title']).to eq '1 release'
      end
    end

    context 'with the sidebar expanded' do
      before do
        visit_milestone
      end

      it 'shows "Version 5" in the "Release" section' do
        expect(sidebar_release_block).to have_content 'Release Version 5'
      end
    end
  end

  context 'when the milestone is associated with multiple releases' do
    before do
      (5..10).each do |num|
        released_at = Time.zone.parse('2019-10-04') + num.months
        create(:release, project: project, name: "Version #{num}", milestones: [milestone], released_at: released_at)
      end
    end

    context 'with the sidebar collapsed' do
      before do
        visit_milestone(collapsed: true)
      end

      it 'shows "6" in the "Releases" section' do
        expect(sidebar_release_block).to have_content '6'
      end

      it 'has a tooltip that reads "6 releases"' do
        expect(sidebar_release_block_collapsed_icon['title']).to eq '6 releases'
      end
    end

    context 'with the sidebar expanded' do
      before do
        visit_milestone
      end

      it 'shows a shortened list of releases in the "Releases" section' do
        expect(sidebar_release_block).to have_content 'Releases Version 10 • Version 9 • Version 8 • 3 more releases'
      end
    end
  end
end
