# frozen_string_literal: true

require 'spec_helper'

describe 'Multi-file editor new file', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_path(project)

    wait_for_requests

    click_link('Web IDE')

    wait_for_requests
  end

  after do
    set_cookie('new_repo', 'false')
  end

  it 'creates file in current directory' do
    first('.ide-tree-actions button').click

    page.within('.modal') do
      find('.form-control').set('file name')

      click_button('Create file')
    end

    wait_for_requests

    find('.js-ide-commit-mode').click

    find('.multi-file-commit-list-item').hover
    click_button 'Stage'

    fill_in('commit-message', with: 'commit message ide')

    page.within '.multi-file-commit-form' do
      click_button('Commit')
    end

    expect(page).to have_content('file name')
  end
end
