require 'spec_helper'

feature 'Path Locks', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:tree_path) { project_tree_path(project, project.repository.root_ref) }

  before do
    allow(project).to receive(:feature_available?).with(:file_locks) { true }

    project.team << [user, :master]
    sign_in(user)

    visit tree_path
  end

  scenario 'Locking folders' do
    within '.tree-content-holder' do
      click_link "encoding"
    end
    click_link "Lock"
    visit tree_path

    expect(page).to have_selector('.fa-lock')
  end

  scenario 'Locking files' do
    page_tree = find('.tree-content-holder')

    within page_tree do
      click_link "VERSION"
    end

    within '.file-actions' do
      click_link "Lock"
    end

    visit tree_path

    within page_tree do
      expect(page).to have_selector('.fa-lock')
    end
  end

  scenario 'Unlocking files' do
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

  scenario 'Managing of lock list' do
    create :path_lock, path: 'encoding', user: user, project: project

    click_link "Locked Files"

    within '.locks' do
      expect(page).to have_content('encoding')

      find('.btn-remove').click

      expect(page).not_to have_content('encoding')
    end
  end
end
