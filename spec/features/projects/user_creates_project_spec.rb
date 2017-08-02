require 'spec_helper'

feature 'User creates a project', js: true do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    create(:personal_key, user: user)
    visit(new_project_path)
  end

  it 'creates a new project' do
    fill_in(:project_path, with: 'Empty')

    page.within('#content-body') do
      click_button('Create project')
    end

    project = Project.last

    expect(current_path).to eq(project_path(project))
    expect(page).to have_content('Empty')
    expect(page).to have_content('git init')
    expect(page).to have_content('git remote')
    expect(page).to have_content(project.url_to_repo)
  end
end
