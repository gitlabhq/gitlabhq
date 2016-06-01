require 'spec_helper'

feature 'Merge request created from fork' do
  given(:user) { create(:user) }
  given(:project) { create(:project, :public) }
  given(:fork_project) { create(:project, :public) }

  given!(:merge_request) do
    create(:forked_project_link, forked_to_project: fork_project,
                                 forked_from_project: project)

    create(:merge_request, source_project: fork_project,
                           target_project: project,
                           description: 'Test merge request')
  end

  before do
    project.team << [user, :master]

    login_as user
    visit namespace_project_merge_request_path(project.namespace,
                                               project, merge_request)
  end

  scenario 'user can access merge request' do
    expect(page).to have_content 'Test merge request'
  end
end
