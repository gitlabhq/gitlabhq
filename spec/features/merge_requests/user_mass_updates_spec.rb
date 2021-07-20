# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge requests > User mass updates', :js do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.creator }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  before do
    project.add_maintainer(user)
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
      merge_request.close
      visit project_merge_requests_path(project, state: 'merged')

      click_button 'Edit merge requests'

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
    let(:milestone) { create(:milestone, project: project) }

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
    click_button 'Edit merge requests'
    check 'Select all'
    click_button 'Select status'
    click_button text
    click_update_merge_requests_button
  end

  def change_assignee(text)
    click_button 'Edit merge requests'
    check 'Select all'
    within 'aside[aria-label="Bulk update"]' do
      click_button 'Select assignee'
      wait_for_requests
      click_link text
    end
    click_update_merge_requests_button
  end

  def change_milestone(text)
    click_button 'Edit merge requests'
    check 'Select all'
    click_button 'Select milestone'
    click_link text
    click_update_merge_requests_button
  end

  def click_update_merge_requests_button
    click_button 'Update all'
    wait_for_requests
  end
end
