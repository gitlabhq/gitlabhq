require 'spec_helper'

describe 'create a merge request that allows maintainers to push', :js do
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

  it 'allows setting maintainer push possible' do
    visit_new_merge_request

    check 'Allow edits from maintainers'

    click_button 'Submit merge request'

    wait_for_requests

    expect(page).to have_content('Allows edits from maintainers')
  end

  it 'shows a message when one of the projects is private' do
    source_project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

    visit_new_merge_request

    expect(page).to have_content('Not available for private projects')
  end

  it 'shows a message when the source branch is protected' do
    create(:protected_branch, project: source_project, name: 'fix')

    visit_new_merge_request

    expect(page).to have_content('Not available for protected branches')
  end

  context 'when the merge request is being created within the same project' do
    let(:source_project) { target_project }

    it 'hides the checkbox if the merge request is being created within the same project' do
      target_project.add_developer(user)

      visit_new_merge_request

      expect(page).not_to have_content('Allows edits from maintainers')
    end
  end

  context 'when a maintainer tries to edit the option' do
    let(:maintainer) { create(:user) }
    let(:merge_request) do
      create(:merge_request,
             source_project: source_project,
             target_project: target_project,
             source_branch: 'fixes')
    end

    before do
      target_project.add_master(maintainer)

      sign_in(maintainer)
    end

    it 'it hides the option from maintainers' do
      visit edit_project_merge_request_path(target_project, merge_request)

      expect(page).not_to have_content('Allows edits from maintainers')
    end
  end
end
