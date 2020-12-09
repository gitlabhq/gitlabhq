# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Milestone' do
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:user) { create(:user) }

  before do
    create(:group_member, group: group, user: user)
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'Create a milestone' do
    it 'shows an informative message for a new milestone' do
      visit new_project_milestone_path(project)

      page.within '.milestone-form' do
        fill_in "milestone_title", with: '8.7'
        fill_in "milestone_start_date", with: '2016-11-16'
        fill_in "milestone_due_date", with: '2016-12-16'
      end

      find('input[name="commit"]').click

      expect(find('[data-testid="no-issues-alert"]')).to have_content('Assign some issues to this milestone.')
      expect(page).to have_content('Nov 16, 2016–Dec 16, 2016')
    end
  end

  describe 'Open a milestone with closed issues' do
    it 'shows an informative message' do
      milestone = create(:milestone, project: project, title: 8.7)

      create(:issue, title: "Bugfix1", project: project, milestone: milestone, state: "closed")
      visit project_milestone_path(project, milestone)

      expect(find('[data-testid="all-issues-closed-alert"]')).to have_content('All issues for this milestone are closed. You may close this milestone now.')
    end
  end

  describe 'Open a project milestone with an existing title' do
    it 'displays validation message when there is a project milestone with same title' do
      milestone = create(:milestone, project: project, title: 8.7)

      visit new_project_milestone_path(project)
      page.within '.milestone-form' do
        fill_in "milestone_title", with: milestone.title
      end
      find('input[name="commit"]').click

      expect(find('.alert-danger')).to have_content('already being used for another group or project milestone.')
    end

    it 'displays validation message when there is a group milestone with same title' do
      milestone = create(:milestone, project_id: nil, group: project.group, title: 8.7)

      visit new_group_milestone_path(project.group)

      page.within '.milestone-form' do
        fill_in "milestone_title", with: milestone.title
      end
      find('input[name="commit"]').click

      expect(find('.alert-danger')).to have_content('already being used for another group or project milestone.')
    end
  end

  describe 'Open a milestone', :js do
    it 'shows total issue time spent correctly when no time has been logged' do
      milestone = create(:milestone, project: project, title: 8.7)

      visit project_milestone_path(project, milestone)

      wait_for_requests

      page.within('[data-testid="noTrackingPane"]') do
        expect(page).to have_content 'No estimate or time spent'
      end
    end

    it 'shows total issue time spent' do
      milestone = create(:milestone, project: project, title: 8.7)
      issue1 = create(:issue, project: project, milestone: milestone)
      issue2 = create(:issue, project: project, milestone: milestone)
      issue1.spend_time(duration: 3600, user_id: user.id)
      issue1.save!
      issue2.spend_time(duration: 7200, user_id: user.id)
      issue2.save!

      visit project_milestone_path(project, milestone)

      wait_for_requests

      page.within('[data-testid="spentOnlyPane"]') do
        expect(page).to have_content 'Spent: 3h'
      end
    end
  end

  describe 'Deleting a milestone' do
    it "the delete milestone button does not show for unauthorized users" do
      create(:milestone, project: project, title: 8.7)
      sign_out(user)

      visit group_milestones_path(group)

      expect(page).to have_selector('.js-delete-milestone-button', count: 0)
    end
  end

  describe 'reopen closed milestones' do
    before do
      create(:milestone, :closed, project: project)
    end

    describe 'group milestones page' do
      it 'reopens the milestone' do
        visit group_milestones_path(group, { state: 'closed' })

        click_link 'Reopen Milestone'

        expect(page).not_to have_selector('.status-box-closed')
        expect(page).to have_selector('.status-box-open')
      end
    end

    describe 'project milestones page' do
      it 'reopens the milestone' do
        visit project_milestones_path(project, { state: 'closed' })

        click_link 'Reopen Milestone'

        expect(page).not_to have_selector('.status-box-closed')
        expect(page).to have_selector('.status-box-open')
      end
    end
  end
end
