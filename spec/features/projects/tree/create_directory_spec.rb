require 'spec_helper'

feature 'Multi-file editor new directory', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_master(user)
    sign_in(user)

    set_cookie('new_repo', 'true')

    visit project_tree_path(project, :master)

    wait_for_requests
  end

  it 'creates directory in current directory' do
    find('.add-to-tree').click

    click_link('New directory')

    page.within('.modal') do
      find('.form-control').set('foldername')

      click_button('Create directory')
    end

    find('.multi-file-commit-panel-collapse-btn').click

    fill_in('commit-message', with: 'commit message')

    click_button('Commit')

    expect(page).to have_selector('td', text: 'commit message')
  end
end
