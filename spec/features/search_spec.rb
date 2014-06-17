require 'spec_helper'

describe "Search", feature: true  do
  before do
    login_as :user
    @project = create(:project, namespace: @user.namespace)
    @project.team << [@user, :reporter]
    visit search_path

    within '.search-holder' do
      fill_in "search", with: @project.name[0..3]
      click_button "Search"
    end
  end

  it "should show project in search results" do
    page.should have_content @project.name
  end
end

