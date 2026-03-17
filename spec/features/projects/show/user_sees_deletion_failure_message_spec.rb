# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User sees a deletion failure message', feature_category: :groups_and_projects do
  let(:project) { create(:project, :empty_repo, pending_delete: true) }

  before do
    sign_in(project.first_owner)
  end

  it 'shows error message if deletion for project fails' do
    project.deletion_error = "Something went wrong"
    project.project_namespace.namespace_details.save!
    project.update!(pending_delete: false)

    visit project_path(project)

    expect(page).to have_selector('.project-deletion-failed-message')
    expect(page).to have_content("This project was scheduled for deletion, but failed with the following message: #{project.deletion_error}")
  end
end
