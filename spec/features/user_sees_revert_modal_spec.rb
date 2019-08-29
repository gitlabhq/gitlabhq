# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User sees revert modal', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    sign_in(user)
    visit(project_merge_request_path(project, merge_request))
    click_button('Merge')

    wait_for_requests

    visit(merge_request_path(merge_request))
    click_link('Revert')
  end

  it 'shows the revert modal' do
    page.within('.modal-header') do
      expect(page).to have_content 'Revert this merge request'
    end
  end

  it 'closes the revert modal with escape keypress' do
    find('#modal-revert-commit').send_keys(:escape)

    expect(page).not_to have_selector('#modal-revert-commit', visible: true)
  end
end
