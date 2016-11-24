require 'rails_helper'

feature 'Ref switcher', feature: true, js: true do
  include WaitForAjax
  let(:user)      { create(:user) }
  let(:project)   { create(:project, :public) }

  before do
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_tree_path(project.namespace, project, 'master')
  end

  it 'allow user to change ref by enter key' do
    click_button 'master'
    wait_for_ajax

    page.within '.project-refs-form' do
      input = find('input[type="search"]')
      input.set 'expand'

      input.native.send_keys :down
      input.native.send_keys :down
      input.native.send_keys :enter
    end

    expect(page).to have_title 'expand-collapse-files'
  end

  it "user selects ref with special characters" do
    click_button 'master'
    wait_for_ajax

    page.within '.project-refs-form' do
      page.fill_in 'Search branches and tags', with: "'test'"
      click_link "'test'"
    end

    expect(page).to have_title "'test'"
  end
end
