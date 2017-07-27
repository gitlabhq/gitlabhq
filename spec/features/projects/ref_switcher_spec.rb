require 'rails_helper'

feature 'Ref switcher', js: true do
  let(:user)      { create(:user) }
  let(:project)   { create(:project, :public) }

  before do
    project.team << [user, :master]
    sign_in(user)
    visit project_tree_path(project, 'master')
  end

  it 'allow user to change ref by enter key' do
    click_button 'master'
    wait_for_requests

    page.within '.project-refs-form' do
      input = find('input[type="search"]')
      input.set 'binary'
      wait_for_requests

      expect(find('.dropdown-content ul')).to have_selector('li', count: 6)

      page.within '.dropdown-content ul' do
        input.native.send_keys :enter
      end
    end

    expect(page).to have_title 'binary-encoding'
  end

  it "user selects ref with special characters" do
    click_button 'master'
    wait_for_requests

    page.within '.project-refs-form' do
      page.fill_in 'Search branches and tags', with: "'test'"
      click_link "'test'"
    end

    expect(page).to have_title "'test'"
  end
end
