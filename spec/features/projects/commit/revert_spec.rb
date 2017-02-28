require 'spec_helper'

describe 'Revert Commits', :js do
  let(:project) { create(:project) }

  before do
    login_as :user
    project.team << [@user, :master]

    visit namespace_project_commit_path(project.namespace, project, project.commit.sha)
  end

  it 'creates merge request for revert' do
    page.within '.header-action-buttons' do
      find('.dropdown-toggle').click
    end

    click_link 'Revert'

    click_button 'Revert'

    expect(page).to have_content("From revert-#{project.commit.short_id} into master")
  end
end
