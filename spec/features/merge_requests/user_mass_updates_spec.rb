# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge requests > User mass updates', :js, feature_category: :code_review_workflow do
  include ListboxHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.creator }
  let_it_be(:user2) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:merged_merge_request) { create(:merge_request, :merged, source_project: project, target_project: project) }

  before_all do
    project.add_maintainer(user)
    project.add_maintainer(user2)
  end

  before do
    sign_in(user)
  end

  context 'status' do
    describe 'close merge request' do
      before do
        visit project_merge_requests_path(project)
      end

      it 'closes merge request', :js do
        change_status('Closed')

        expect(page).to have_selector('.merge-request', count: 0)
      end
    end

    describe 'reopen merge request' do
      before do
        merge_request.close
        visit project_merge_requests_path(project, state: 'closed')
      end

      it 'reopens merge request', :js do
        change_status('Open')

        expect(page).to have_selector('.merge-request', count: 0)
      end
    end

    it 'does not exist in merged state' do
      visit project_merge_requests_path(project, state: 'merged')

      click_button 'Bulk edit'

      expect(page).not_to have_button 'Select status'
    end
  end

  context 'assignee' do
    describe 'set assignee' do
      before do
        visit project_merge_requests_path(project)
      end

      it 'updates merge request with assignee' do
        change_assignee(user.name)

        expect(find('.merge-request')).to have_link "Assigned to #{user.name}"
      end
    end

    describe 'remove assignee' do
      before do
        merge_request.assignees = [user]
        visit project_merge_requests_path(project)
      end

      it 'removes assignee from the merge request' do
        change_assignee('Unassigned')

        expect(find('.merge-request')).not_to have_link "Assigned to #{user.name}"
      end
    end
  end

  context 'milestone' do
    let!(:milestone) { create(:milestone, project: project) }

    describe 'set milestone' do
      before do
        visit project_merge_requests_path(project)
      end

      it 'updates merge request with milestone' do
        change_milestone(milestone.title)

        expect(find('.merge-request')).to have_content milestone.title
      end
    end

    describe 'unset milestone' do
      before do
        merge_request.milestone = milestone
        merge_request.save!
        visit project_merge_requests_path(project)
      end

      it 'removes milestone from the merge request' do
        change_milestone("No milestone")

        expect(find('.merge-request')).not_to have_content milestone.title
      end
    end
  end

  def change_status(text)
    click_button 'Bulk edit'
    check 'Select all'
    select_from_listbox(text, from: 'Select status')
    click_update_merge_requests_button
  end

  def change_assignee(text)
    click_button 'Bulk edit'
    check 'Select all'
    within 'aside[aria-label="Bulk update"]' do
      click_button 'Select assignee'
      wait_for_requests
      click_button text
    end
    click_update_merge_requests_button
  end

  def change_milestone(text)
    click_button 'Bulk edit'
    check 'Select all'
    click_button 'Select milestone'
    click_button text
    click_update_merge_requests_button
  end

  def click_update_merge_requests_button
    click_button 'Update selected'
    wait_for_requests
  end
end
