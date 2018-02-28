require 'spec_helper'

feature 'Multi-file editor new file', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_master(user)
    sign_in(user)

    set_cookie('new_repo', 'true')

    visit project_tree_path(project, :master)

    wait_for_requests
  end

  it 'creates file in current directory' do
    find('.add-to-tree').click

    click_link('New file')

    page.within('.popup-dialog') do
      find('.form-control').set('filename')

      click_button('Create file')
    end

    fill_in('commit-message', with: 'commit message')

    click_button('Commit 1 file')

    expect(page).to have_selector('td', text: 'commit message')
  end
end
