require 'spec_helper'

describe 'Multi-file editor new directory', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
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
    all('.ide-tree-actions button').last.click

    page.within('.modal') do
      find('.form-control').set('folder name')

      click_button('Create directory')
    end

    first('.ide-tree-actions button').click

    page.within('.modal-dialog') do
      find('.form-control').set('file name')

      click_button('Create file')
    end

    wait_for_requests

    find('.js-ide-commit-mode').click

    find('.multi-file-commit-list-item').hover
    first('.multi-file-discard-btn .btn').click

    fill_in('commit-message', with: 'commit message ide')

    click_button('Commit')

    find('.js-ide-edit-mode').click

    expect(page).to have_content('folder name')
  end
end
