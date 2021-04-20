# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User sees a deletion failure message' do
  let(:project) { create(:project, :empty_repo, pending_delete: true) }

  before do
    sign_in(project.owner)
  end

  it 'shows error message if deletion for project fails' do
    project.update!(delete_error: "Something went wrong", pending_delete: false)

    visit project_path(project)

    expect(page).to have_selector('.project-deletion-failed-message')
    expect(page).to have_content("This project was scheduled for deletion, but failed with the following message: #{project.delete_error}")
  end
end
