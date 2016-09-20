require 'rails_helper'

feature 'Milestone', feature: true do
  include WaitForAjax

  let(:project) { create(:empty_project, :public) }
  let(:user)   { create(:user) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  feature 'Create a milestone' do
    scenario 'shows an informative message for a new milestone' do
      visit new_namespace_project_milestone_path(project.namespace, project)
      page.within '.milestone-form' do
        fill_in "milestone_title", with: '8.7'
      end
      find('input[name="commit"]').click

      expect(find('.alert-success')).to have_content('Assign some issues to this milestone.')
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

  feature 'Open a milestone with an existing title' do
    scenario 'displays validation message' do
      milestone = create(:milestone, project: project, title: 8.7)

      visit new_namespace_project_milestone_path(project.namespace, project)
      page.within '.milestone-form' do
        fill_in "milestone_title", with: milestone.title
      end
      find('input[name="commit"]').click

      expect(find('.alert-danger')).to have_content('Title has already been taken')
    end
  end
end
