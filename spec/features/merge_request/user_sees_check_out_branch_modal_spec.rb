# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees check out branch modal', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
    wait_for_requests
    click_button('Check out branch')
  end

  it 'shows the check out branch modal' do
    expect(page).to have_content('Check out, review, and merge locally')
  end

  it 'closes the check out branch modal with the close action' do
    find('.modal button[aria-label="Close"]').click

    expect(page).not_to have_content('Check out, review, and merge locally')
  end
end
