# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits a merge request', :js do
  include Select2Helper

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(edit_project_merge_request_path(project, merge_request))
  end

  describe 'Squash commits' do
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

  it 'changes the target branch' do
    expect(page).to have_content('From master into feature')

    select2('merge-test', from: '#merge_request_target_branch')
    click_button('Save changes')

    expect(page).to have_content("Request to merge #{merge_request.source_branch} into merge-test")
    expect(page).to have_content("changed target branch from #{merge_request.target_branch} to merge-test")
  end
end
