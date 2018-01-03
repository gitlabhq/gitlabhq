require 'spec_helper'

describe 'User reverts a merge request', :js do
  let(:merge_request) { create(:merge_request, :with_diffs, :simple, source_project: project) }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))

    click_button('Merge')

    visit(merge_request_path(merge_request))
  end

  it 'reverts a merge request' do
    find("a[href='#modal-revert-commit']").click

    page.within('#modal-revert-commit') do
      uncheck('create_merge_request')
      click_button('Revert')
    end

    expect(page).to have_content('The merge request has been successfully reverted.')

    wait_for_requests
  end

  it 'does not revert a merge request that was previously reverted' do
    find("a[href='#modal-revert-commit']").click

    page.within('#modal-revert-commit') do
      uncheck('create_merge_request')
      click_button('Revert')
    end

    find("a[href='#modal-revert-commit']").click

    page.within('#modal-revert-commit') do
      uncheck('create_merge_request')
      click_button('Revert')
    end

    expect(page).to have_content('Sorry, we cannot revert this merge request automatically.')
  end

  it 'reverts a merge request in a new merge request' do
    find("a[href='#modal-revert-commit']").click

    page.within('#modal-revert-commit') do
      click_button('Revert')
    end

    expect(page).to have_content('The merge request has been successfully reverted. You can now submit a merge request to get this change into the original branch.')
  end
end
