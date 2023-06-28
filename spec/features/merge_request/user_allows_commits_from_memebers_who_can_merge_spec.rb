# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'create a merge request, allowing commits from members who can merge to the target branch', :js,
  feature_category: :code_review_workflow do
  include ProjectForksHelper
  let(:user) { create(:user) }
  let(:target_project) { create(:project, :public, :repository) }
  let(:source_project) { fork_project(target_project, user, repository: true, namespace: user.namespace) }

  def visit_new_merge_request
    visit project_new_merge_request_path(
      source_project,
      merge_request: {
        source_project_id: source_project.id,
        target_project_id: target_project.id,
        source_branch: 'fix',
        target_branch: 'master'
      })
  end

  before do
    sign_in(user)
  end

  it 'allows setting possible', :sidekiq_might_not_need_inline do
    visit_new_merge_request

    check 'Allow commits from members who can merge to the target branch'

    click_button 'Create merge request'

    wait_for_requests

    expect(page).to have_content('Members who can merge are allowed to add commits.')
  end

  it 'shows a message when one of the projects is private', :sidekiq_might_not_need_inline do
    source_project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

    visit_new_merge_request

    expect(page).to have_content('Not available for private projects')
  end

  it 'shows a message when the source branch is protected', :sidekiq_might_not_need_inline do
    create(:protected_branch, project: source_project, name: 'fix')

    visit_new_merge_request

    expect(page).to have_content('Not available for protected branches')
  end

  context 'when the merge request is being created within the same project' do
    let(:source_project) { target_project }

    it 'hides the checkbox if the merge request is being created within the same project' do
      target_project.add_developer(user)

      visit_new_merge_request

      expect(page).not_to have_content('The fork project allows commits from members who can write to the target branch.')
    end
  end

  context 'when a member who can merge tries to edit the option' do
    let(:member) { create(:user) }
    let(:merge_request) do
      create(
        :merge_request,
        source_project: source_project,
        target_project: target_project,
        source_branch: 'fixes'
      )
    end

    before do
      target_project.add_maintainer(member)

      sign_in(member)
    end

    it 'hides the option from members' do
      visit edit_project_merge_request_path(target_project, merge_request)

      expect(page).not_to have_content('The fork project allows commits from members who can write to the target branch.')
    end
  end
end
