require 'spec_helper'

feature 'pipeline badge' do
  let(:project) { create(:project, :repository, :public) }

  # this can't be tested in the controller, as it bypasses the rails router
  # and constructs a route based on the controller being tested
  # Keep around until 10.0, see gitlab-org/gitlab-ce#35307
  scenario 'user request the deprecated build status badge' do
    visit build_project_badges_path(project, ref: project.default_branch, format: :svg)

    expect(page.status_code).to eq(200)
  end
end
