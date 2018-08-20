require 'spec_helper'

describe 'Path Locks', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:tree_path) { project_tree_path(project, project.repository.root_ref) }

  before do
    allow(project).to receive(:feature_available?).with(:file_locks) { true }

    project.add_maintainer(user)
    sign_in(user)

    visit tree_path

    wait_for_requests
  end

  it 'Locking folders' do
    within '.tree-content-holder' do
      click_link "encoding"
    end
    click_link "Lock"

    expect(page).to have_selector('.fa-lock')

    visit tree_path

    expect(page).to have_selector('.fa-lock')
  end

  it 'Locking files' do
    page_tree = find('.tree-content-holder')

    within page_tree do
      click_link "VERSION"
    end

    within '.file-actions' do
      click_link "Lock"

      expect(page).to have_link('Unlock')
    end

    visit tree_path

    within page_tree do
      expect(page).to have_selector('.fa-lock')
    end
  end

  it 'Unlocking files' do
    within find('.tree-content-holder') do
      click_link "VERSION"
    end

    within '.file-actions' do
      click_link "Lock"

      expect(page).to have_link('Unlock')
    end

    within '.file-actions' do
      click_link "Unlock"

      expect(page).to have_link('Lock')
    end
  end

  it 'Managing of lock list' do
    create :path_lock, path: 'encoding', user: user, project: project

    click_link "Locked Files"

    within '.locks' do
      expect(page).to have_content('encoding')

      accept_confirm { find('.btn-remove').click }

      expect(page).not_to have_content('encoding')
    end
  end
end
