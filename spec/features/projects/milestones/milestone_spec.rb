require 'spec_helper'

feature 'Project milestone' do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, project: project) }

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
        expect(page).to have_selector '.nav-links li.active', count: 1
        expect(find('.nav-links li.active')).to have_content 'Issues'
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

  context 'when project has disabled issues' do
    before do
      project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
      visit project_milestone_path(project, milestone)
    end

    it 'hides issues tab' do
      within('#content-body') do
        expect(page).not_to have_link 'Issues', href: '#tab-issues'
        expect(page).to have_selector '.nav-links li.active', count: 1
        expect(find('.nav-links li.active')).to have_content 'Merge Requests'
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
        find('.milestone-sidebar .gutter-toggle').click
      end

      it 'shows the total MR and issue counts' do
        find('.milestone-sidebar .block', match: :first)

        aggregate_failures 'MR and issue blocks' do
          expect(find('.milestone-sidebar .block.issues')).to have_content 1
          expect(find('.milestone-sidebar .block.merge-requests')).to have_content 0
        end
      end
    end
  end
end
