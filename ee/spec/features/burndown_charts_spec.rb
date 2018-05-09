require 'spec_helper'

feature 'Burndown charts' do
  let(:current_user) { create(:user) }
  let(:milestone) do
    create(:milestone, project: project,
                       group: group,
                       start_date: Date.current,
                       due_date: Date.tomorrow)
  end

  before do
    sign_in(current_user)
  end

  describe 'for project milestones' do
    let(:group) { nil }
    let(:project) { create(:project) }

    before do
      project.add_master(current_user)
    end

    it 'presents burndown charts when available' do
      stub_licensed_features(burndown_charts: true)

      visit project_milestone_path(milestone.project, milestone)

      expect(page).to have_css('.burndown-chart')
      expect(page).to have_content('Burndown chart')
    end

    it 'presents burndown charts promotion correctly' do
      stub_licensed_features(burndown_charts: false)
      allow(License).to receive(:current) { nil }

      visit project_milestone_path(milestone.project, milestone)

      expect(page).not_to have_css('.burndown-chart')
      expect(page).to have_content('Improve milestones with Burndown Charts')
    end
  end

  describe 'for group milestones' do
    let(:group) { create(:group) }
    let(:project) { nil }

    before do
      group.add_master(current_user)
    end

    it 'presents burndown charts when available' do
      stub_licensed_features(group_burndown_charts: true)

      visit group_milestone_path(milestone.group, milestone)

      expect(page).to have_css('div.burndown-chart')
      expect(page).to have_content('Burndown chart')
    end

    it 'presents burndown charts promotion correctly' do
      stub_licensed_features(group_burndown_charts: false)
      allow(License).to receive(:current) { nil }

      visit group_milestone_path(milestone.group, milestone)

      expect(page).not_to have_css('.burndown-chart')
      expect(page).to have_content('Improve milestones with Burndown Charts')
    end
  end

  describe 'grouped by title milestones' do
    let(:group) { nil }
    let(:project) { create(:project) }

    before do
      project.add_master(current_user)
    end

    it 'does not present burndown chart or promotion' do
      allow(License).to receive(:current) { nil }
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }

      visit dashboard_milestone_path(milestone.safe_title, title: milestone.title)

      expect(page).to have_content('manage issues from multiple projects in the same milestone.')
      expect(page).not_to have_css('.burndown-chart')
      expect(page).not_to have_content('Improve milestones with Burndown Charts')
    end
  end
end
