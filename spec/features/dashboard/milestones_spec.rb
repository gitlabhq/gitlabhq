# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard > Milestones' do
  describe 'as anonymous user' do
    before do
      visit dashboard_milestones_path
    end

    it 'is redirected to sign-in page' do
      expect(current_path).to eq new_user_session_path
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

    it 'sees milestones' do
      expect(current_path).to eq dashboard_milestones_path
      expect(page).to have_content(milestone.title)
      expect(page).to have_content(group.name)
      expect(first('.milestone')).to have_content('Merge Requests')
    end

    describe 'new milestones dropdown', :js do
      it 'takes user to a new milestone page', :js do
        find('.new-project-item-select-button').click

        page.within('.select2-results') do
          first('.select2-result-label').click
        end

        find('.new-project-item-link').click

        expect(current_path).to eq(new_group_milestone_path(group))
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
      expect(current_path).to eq dashboard_milestones_path
      expect(page).to have_content(milestone.title)
      expect(first('.milestone')).to have_no_content('Merge Requests')
    end
  end
end
