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

      expect(page).to have_content 'expand-collapse-files'
    end
  end
end
