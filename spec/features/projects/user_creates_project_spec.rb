require 'spec_helper'

feature 'User creates a project', :js do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    create(:personal_key, user: user)
  end

  it 'creates a new project' do
    visit(new_project_path)

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

  context 'in a subgroup they do not own', :nested_groups do
    let(:parent) { create(:group) }
    let!(:subgroup) { create(:group, parent: parent) }

    before do
      parent.add_owner(user)
    end

    it 'creates a new project' do
      visit(new_project_path)

      fill_in :project_path, with: 'a-subgroup-project'

      page.find('.js-select-namespace').click
      page.find("div[role='option']", text: subgroup.full_path).click

      page.within('#content-body') do
        click_button('Create project')
      end

      expect(page).to have_content("Project 'a-subgroup-project' was successfully created")

      project = Project.last

      expect(project.namespace).to eq(subgroup)
    end
  end
end
