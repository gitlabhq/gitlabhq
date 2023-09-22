# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Project overview when default branch collides with tag", :js, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :empty_repo) }
  let(:user) { project.first_owner }

  before_all do
    # Create a branch called main that does not contain a readme (this will be the default branch)
    project.repository.create_file(
      project.creator,
      'NOTREADME.md',
      '',
      message: "Initial commit",
      branch_name: 'main'
    )

    # Create a branch called readme_branch that contains a readme
    project.repository.create_file(
      project.creator,
      'README.md',
      'readme',
      message: "Add README.md",
      branch_name: 'readme_branch'
    )

    # Create a tag called main pointing to readme_branch
    project.repository.add_tag(
      project.creator,
      'main',
      'readme_branch'
    )
  end

  before do
    sign_in(user)
    visit project_path(project)
  end

  it "shows last commit" do
    page.within(".commit-detail") do
      expect(page).to have_content('Initial commit')
    end

    page.execute_script(%{
      document.getElementsByClassName('tree-content-holder')[0].scrollIntoView()}
                       )
    wait_for_all_requests

    page.within(".tree-content-holder") do
      expect(page).to have_content('Initial commit')
    end
  end

  it 'has a button to button to add readme' do
    expect(page).to have_link 'Add README'
  end
end
