# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard > Milestones', :js, feature_category: :team_planning do
  describe 'as anonymous user' do
    before do
      visit dashboard_milestones_path
    end

    it 'is redirected to sign-in page' do
      expect(page).to have_current_path new_user_session_path, ignore_query: true
    end
  end

  describe 'as logged-in user' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, namespace: user.namespace) }
    let!(:milestone) { create(:milestone, project: project) }
    let!(:milestone2) { create(:milestone, group: group) }

    before do
      group.add_developer(user)
      sign_in(user)
      visit dashboard_milestones_path
    end

    it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_milestones_path, :milestones

    it 'sees milestones' do
      expect(page).to have_current_path dashboard_milestones_path, ignore_query: true
      expect(page).to have_content(milestone.title)
      expect(page).to have_content(group.name)
      expect(first('.milestone').text).to match(%r{\d/\d complete})
      expect(first('.milestone').text).to match(%r{\d%})
    end

    describe 'new milestones dropdown' do
      it 'takes user to a new milestone page' do
        click_button 'Select project to create milestone'

        within_testid('new-resource-dropdown') do
          click_button group.name
          click_link "New milestone in #{group.name}"
        end

        expect(page).to have_current_path(new_group_milestone_path(group), ignore_query: true)
      end
    end
  end

  describe 'with merge requests disabled' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, :merge_requests_disabled, namespace: user.namespace) }
    let!(:milestone) { create(:milestone, project: project) }

    before do
      group.add_developer(user)
      sign_in(user)
      visit dashboard_milestones_path
    end

    it 'does not see milestones' do
      expect(page).to have_current_path dashboard_milestones_path, ignore_query: true
      expect(page).to have_content(milestone.title)
      expect(first('.milestone')).to have_no_content('Merge Requests')
    end
  end
end
