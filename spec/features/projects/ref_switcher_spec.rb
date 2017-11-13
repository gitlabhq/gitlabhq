require 'rails_helper'

feature 'Ref switcher', :js do
  let(:user)      { create(:user) }
  let(:project)   { create(:project, :public, :repository) }

  before do
    project.team << [user, :master]
    set_cookie('new_repo', 'true')
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

      expect(find('.dropdown-content ul')).to have_selector('li', count: 7)

      page.within '.dropdown-content ul' do
        input.native.send_keys :enter
      end
    end

    expect(page).to have_title 'add-pdf-text-binary'
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

  context "create branch" do
    let(:input) { find('.js-new-branch-name') }

    before do
      click_button 'master'
      wait_for_requests

      page.within '.project-refs-form' do
        find(".dropdown-footer-list a").click
      end
    end

    it "shows error message for the invalid branch name" do
      input.set 'foo bar'
      click_button('Create')
      wait_for_requests
      expect(page).to have_content 'Branch name is invalid'
    end

    it "should create new branch properly" do
      input.set 'new-branch-name'
      click_button('Create')
      wait_for_requests
      expect(find('.js-project-refs-dropdown')).to have_content 'new-branch-name'
    end

    it "should create new branch by Enter key" do
      input.set 'new-branch-name-2'
      input.native.send_keys :enter
      wait_for_requests
      expect(find('.js-project-refs-dropdown')).to have_content 'new-branch-name-2'
    end
  end
end
