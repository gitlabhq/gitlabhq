# frozen_string_literal: true

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

    expect(page).to have_content('folder name')

    first('.ide-tree-actions button').click

    page.within('.modal') do
      find('.form-control').set('folder name/file name')

      click_button('Create file')
    end

    wait_for_requests

    find('.js-ide-commit-mode').click

    click_button 'Stage'

    fill_in('commit-message', with: 'commit message ide')

    find(:css, ".js-ide-commit-new-mr input").set(false)

    wait_for_requests

    page.within '.multi-file-commit-form' do
      click_button('Commit')

      wait_for_requests
    end

    find('.js-ide-edit-mode').click

    expect(page).to have_content('folder name')
  end
end
