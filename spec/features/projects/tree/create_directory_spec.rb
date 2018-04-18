require 'spec_helper'

feature 'Multi-file editor new directory', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_tree_path(project, :master)

    wait_for_requests

    click_link('Web IDE')

    wait_for_requests
  end

  after do
    set_cookie('new_repo', 'false')
  end

  it 'creates directory in current directory' do
    find('.add-to-tree').click

    click_link('New directory')

    page.within('.modal') do
      find('.form-control').set('folder name')

      click_button('Create directory')
    end

    find('.add-to-tree').click

    click_link('New file')

    page.within('.modal-dialog') do
      find('.form-control').set('file name')

      click_button('Create file')
    end

    wait_for_requests

    find('.js-ide-commit-mode').click

    fill_in('commit-message', with: 'commit message ide')

    click_button('Commit')

    find('.js-ide-edit-mode').click

    expect(page).to have_content('folder name')
  end
end
