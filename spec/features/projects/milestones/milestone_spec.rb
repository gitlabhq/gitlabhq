require 'spec_helper'

feature 'Project milestone', :feature do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, project: project) }

  before do
    login_as(user)
  end

  context 'when project has enabled issues' do
    before do
      visit namespace_project_milestone_path(project.namespace, project, milestone)
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
      visit namespace_project_milestone_path(project.namespace, project, milestone)
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

<<<<<<< HEAD
  # EE-only
  context 'milestone summary' do
    it 'shows the total weight when sum is greater than zero' do
      create(:issue, project: project, milestone: milestone, weight: 3)
      create(:issue, project: project, milestone: milestone, weight: 1)

      visit milestone_path

      within '.milestone-sidebar' do
        expect(page).to have_content 'Total issue weight 4'
      end
    end

    it 'hides the total weight when sum is equal to zero' do
      create(:issue, project: project, milestone: milestone, weight: nil)
      create(:issue, project: project, milestone: milestone, weight: nil)

      visit milestone_path

      within '.milestone-sidebar' do
        expect(page).to have_content 'Total issue weight None'
      end
    end
  end
  # EE-only

  def milestone_path
    namespace_project_milestone_path(project.namespace, project, milestone)
  end
=======
  context 'when project has an issue' do
    before do
      create(:issue, project: project, milestone: milestone)

      visit namespace_project_milestone_path(project.namespace, project, milestone)
    end

    describe 'the collapsed sidebar' do
      before do
        find('.milestone-sidebar .gutter-toggle').click
      end

      it 'shows the total MR and issue counts' do
        find('.milestone-sidebar .block', match: :first)
        blocks = all('.milestone-sidebar .block')

        aggregate_failures 'MR and issue blocks' do
          expect(blocks[3]).to have_content 1
          expect(blocks[4]).to have_content 0
        end
      end
    end
  end
>>>>>>> ce/master
end
