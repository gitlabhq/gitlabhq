# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User reverts a merge request', :js do
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))

    click_button('Merge')

    wait_for_requests

    # do not reload the page by visiting, let javascript update the page as it will validate we have loaded the modal
    # code correctly on page update that adds the `revert` button
  end

  it 'reverts a merge request', :sidekiq_might_not_need_inline do
    revert_commit

    wait_for_requests

    expect(page).to have_content('The merge request has been successfully reverted.')
  end

  it 'does not revert a merge request that was previously reverted', :sidekiq_might_not_need_inline do
    revert_commit

    revert_commit

    expect(page).to have_content('Sorry, we cannot revert this merge request automatically.')
  end

  it 'reverts a merge request in a new merge request', :sidekiq_might_not_need_inline do
    revert_commit(create_merge_request: true)

    expect(page).to have_content('The merge request has been successfully reverted. You can now submit a merge request to get this change into the original branch.')
  end

  it 'cannot revert a merge requests for an archived project' do
    project.update!(archived: true)

    visit(merge_request_path(merge_request))

    expect(page).not_to have_link('Revert')
  end

  def revert_commit(create_merge_request: false)
    click_button('Revert')

    page.within('[data-testid="modal-commit"]') do
      uncheck('create_merge_request') unless create_merge_request
      click_button('Revert')
    end
  end
end
