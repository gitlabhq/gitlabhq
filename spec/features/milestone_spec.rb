require 'rails_helper'

feature 'Milestone', feature: true do
  let(:group) { create(:group, :public) }
  let(:project) { create(:empty_project, :public, namespace: group) }
  let(:user)   { create(:user) }

  before do
    project.team << [user, :master]
    gitlab_sign_in(user)
  end

  feature 'Create a milestone' do
    scenario 'shows an informative message for a new milestone' do
      visit new_namespace_project_milestone_path(project.namespace, project)

      page.within '.milestone-form' do
        fill_in "milestone_title", with: '8.7'
        fill_in "milestone_start_date", with: '2016-11-16'
        fill_in "milestone_due_date", with: '2016-12-16'
      end

      find('input[name="commit"]').click

      expect(find('.alert-success')).to have_content('Assign some issues to this milestone.')
      expect(page).to have_content('Nov 16, 2016–Dec 16, 2016')
    end
  end

  feature 'Open a milestone with closed issues' do
    scenario 'shows an informative message' do
      milestone = create(:milestone, project: project, title: 8.7)

      create(:issue, title: "Bugfix1", project: project, milestone: milestone, state: "closed")
      visit namespace_project_milestone_path(project.namespace, project, milestone)

      expect(find('.alert-success')).to have_content('All issues for this milestone are closed. You may close this milestone now.')
    end
  end

  feature 'Open a project milestone with an existing title' do
    scenario 'displays validation message when there is a project milestone with same title' do
      milestone = create(:milestone, project: project, title: 8.7)

      visit new_namespace_project_milestone_path(project.namespace, project)
      page.within '.milestone-form' do
        fill_in "milestone_title", with: milestone.title
      end
      find('input[name="commit"]').click

      expect(find('.alert-danger')).to have_content('already being used for another group or project milestone.')
    end

    scenario 'displays validation message when there is a group milestone with same title' do
      milestone = create(:milestone, project_id: nil, group: project.group, title: 8.7)

      visit new_namespace_project_milestone_path(project.namespace, project)
      page.within '.milestone-form' do
        fill_in "milestone_title", with: milestone.title
      end
      find('input[name="commit"]').click

      expect(find('.alert-danger')).to have_content('already being used for another group or project milestone.')
    end
  end
end
