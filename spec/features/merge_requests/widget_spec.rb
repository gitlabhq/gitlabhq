require 'rails_helper'

describe 'Merge request', :feature, :js do
  include WaitForAjax

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_as(user)

    visit new_namespace_project_merge_request_path(
      project.namespace,
      project,
      merge_request: {
        source_project_id: project.id,
        target_project_id: project.id,
        source_branch: 'feature',
        target_branch: 'master'
      }
    )
  end

  it 'shows widget status after creating new merge request' do
    click_button 'Submit merge request'

    expect(find('.mr-state-widget')).to have_content('Checking ability to merge automatically')

    wait_for_ajax

    expect(page).to have_selector('.accept_merge_request')
  end
end
