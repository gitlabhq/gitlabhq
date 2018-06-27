require 'rails_helper'

feature 'Milestone' do
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:user)   { create(:user) }

  before do
    create(:group_member, group: group, user: user)
    project.add_master(user)
    sign_in(user)
  end

  feature 'Create a milestone' do
    scenario 'shows an informative message for a new milestone' do
      visit new_project_milestone_path(project)

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
      visit project_milestone_path(project, milestone)

      expect(find('.alert-success')).to have_content('All issues for this milestone are closed. You may close this milestone now.')
    end
  end

  feature 'Open a project milestone with an existing title' do
    scenario 'displays validation message when there is a project milestone with same title' do
      milestone = create(:milestone, project: project, title: 8.7)

      visit new_project_milestone_path(project)
      page.within '.milestone-form' do
        fill_in "milestone_title", with: milestone.title
      end
      find('input[name="commit"]').click

      expect(find('.alert-danger')).to have_content('already being used for another group or project milestone.')
    end

    scenario 'displays validation message when there is a group milestone with same title' do
      milestone = create(:milestone, project_id: nil, group: project.group, title: 8.7)

      visit new_group_milestone_path(project.group)

      page.within '.milestone-form' do
        fill_in "milestone_title", with: milestone.title
      end
      find('input[name="commit"]').click

      expect(find('.alert-danger')).to have_content('already being used for another group or project milestone.')
    end
  end

  feature 'Open a milestone', :js do
    scenario 'shows total issue time spent correctly when no time has been logged' do
      milestone = create(:milestone, project: project, title: 8.7)

      visit project_milestone_path(project, milestone)

      wait_for_requests

      page.within('.time-tracking-no-tracking-pane') do
        expect(page).to have_content 'No estimate or time spent'
      end
    end

    scenario 'shows total issue time spent' do
      milestone = create(:milestone, project: project, title: 8.7)
      issue1 = create(:issue, project: project, milestone: milestone)
      issue2 = create(:issue, project: project, milestone: milestone)
      issue1.spend_time(duration: 3600, user_id: user.id)
      issue1.save!
      issue2.spend_time(duration: 7200, user_id: user.id)
      issue2.save!

      visit project_milestone_path(project, milestone)

      wait_for_requests

      page.within('.time-tracking-spend-only-pane') do
        expect(page).to have_content 'Spent: 3h'
      end
    end
  end

  feature 'Deleting a milestone' do
    scenario "The delete milestone button does not show for unauthorized users" do
      create(:milestone, project: project, title: 8.7)
      sign_out(user)

      visit group_milestones_path(group)

      expect(page).to have_selector('.js-delete-milestone-button', count: 0)
    end
  end

  feature 'deprecation popover', :js do
    it 'opens deprecation popover' do
      milestone = create(:milestone, project: project)

      visit group_milestone_path(group, milestone, title: milestone.title)

      expect(page).to have_selector('.milestone-deprecation-message')

      find('.milestone-deprecation-message .js-popover-link').click

      expect(page).to have_selector('.popover')
    end
  end
end
