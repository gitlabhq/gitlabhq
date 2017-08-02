require 'rails_helper'

feature 'Group milestones', :js do
  let(:group) { create(:group) }
  let!(:project) { create(:project_empty_repo, group: group) }
  let(:user) { create(:group_member, :master, user: create(:user), group: group ).user }

  before do
    Timecop.freeze

    sign_in(user)
  end

  after do
    Timecop.return
  end

  context 'create a milestone' do
    before do
      visit new_group_milestone_path(group)
    end

    it 'creates milestone with start date' do
      fill_in 'Title', with: 'testing'
      find('#milestone_start_date').click

      page.within(find('.pika-single')) do
        click_button '1'
      end

      click_button 'Create milestone'

      expect(find('.start_date')).to have_content(Date.today.at_beginning_of_month.strftime('%b %-d, %Y'))
    end
  end

  context 'milestones list' do
    let!(:other_project) { create(:project_empty_repo, group: group) }

    let!(:active_group_milestone) { create(:milestone, group: group, state: 'active') }
    let!(:active_project_milestone1) { create(:milestone, project: project, state: 'active', title: 'v1.0') }
    let!(:active_project_milestone2) { create(:milestone, project: other_project, state: 'active', title: 'v1.0') }
    let!(:closed_group_milestone) { create(:milestone, group: group, state: 'closed') }
    let!(:closed_project_milestone1) { create(:milestone, project: project, state: 'closed', title: 'v2.0') }
    let!(:closed_project_milestone2) { create(:milestone, project: other_project, state: 'closed', title: 'v2.0') }

    before do
      visit group_milestones_path(group)
    end

    it 'counts milestones correctly' do
      expect(find('.top-area .active .badge').text).to eq("2")
      expect(find('.top-area .closed .badge').text).to eq("2")
      expect(find('.top-area .all .badge').text).to eq("4")
    end

    it 'lists legacy group milestones and group milestones' do
      legacy_milestone = GroupMilestone.build_collection(group, group.projects, { state: 'active' }).first

      expect(page).to have_selector("#milestone_#{active_group_milestone.id}", count: 1)
      expect(page).to have_selector("#milestone_#{legacy_milestone.milestones.first.id}", count: 1)
    end
  end
end
