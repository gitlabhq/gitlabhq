# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits a merge request', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(edit_project_merge_request_path(project, merge_request))
  end

  describe 'Squash commits' do
    it 'override MR setting if "Required" is saved' do
      merge_request.update!(squash: false)

      project.project_setting.update!(squash_option: 'always')
      visit(edit_project_merge_request_path(project, merge_request))
      click_button('Save changes')

      project.project_setting.update!(squash_option: 'default_off')
      visit(edit_project_merge_request_path(project, merge_request))

      expect(find("#merge_request_squash").selected?).to be(true)
    end

    it 'recovers MR squash setting if "Required" is not saved' do
      merge_request.update!(squash: false)

      project.project_setting.update!(squash_option: 'always')
      visit(edit_project_merge_request_path(project, merge_request))

      project.project_setting.update!(squash_option: 'default_on')
      visit(edit_project_merge_request_path(project, merge_request))

      expect(find("#merge_request_squash").selected?).to be(false)
    end

    it 'does not override MR squash setting if "Do not allow" is saved' do
      merge_request.update!(squash: true)

      project.project_setting.update!(squash_option: 'never')
      visit(edit_project_merge_request_path(project, merge_request))
      click_button('Save changes')

      expect(merge_request.squash).to be true
    end

    it 'displays "Required in this project" for "Required" project setting squash option' do
      project.project_setting.update!(squash_option: 'always')
      visit(edit_project_merge_request_path(project, merge_request))

      expect(page).to have_content('Squash commits when merge request is accepted.')
      expect(page).to have_content("Required in this project")
    end

    it 'does not display message for "Allow" project setting squash option' do
      project.project_setting.update!(squash_option: 'default_off')
      visit(edit_project_merge_request_path(project, merge_request))

      expect(page).to have_content('Squash commits when merge request is accepted.')
      expect(page).not_to have_content("Required in this project")
    end

    it 'does not display message for "Encourage" project setting squash option' do
      project.project_setting.update!(squash_option: 'default_on')
      visit(edit_project_merge_request_path(project, merge_request))

      expect(page).to have_content('Squash commits when merge request is accepted.')
      expect(page).not_to have_content("Required in this project")
    end

    it 'is hidden for "Do not allow" project setting squash option' do
      project.project_setting.update!(squash_option: 'never')
      visit(edit_project_merge_request_path(project, merge_request))

      expect(page).not_to have_content('Squash commits when merge request is accepted.')
      expect(page).not_to have_css('#merge_request_squash')
    end
  end

  describe 'changing target branch' do
    it 'allows user to change target branch' do
      expect(page).to have_content('From master into feature')

      first('.js-target-branch').click

      wait_for_requests

      first('.js-target-branch-dropdown a', text: 'merge-test').click

      click_button('Save changes')

      expect(page).to have_content("requested to merge #{merge_request.source_branch} into merge-test")
      expect(page).to have_content("changed target branch from #{merge_request.target_branch} to merge-test")
    end

    describe 'merged merge request' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged) }

      it 'does not allow user to change target branch' do
        expect(page).to have_content('From master into feature')
        expect(page).not_to have_selector('.js-target-branch.js-compare-dropdown')
      end
    end
  end

  it_behaves_like 'rich text editor - common'
end
