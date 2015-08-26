require 'spec_helper'

describe "Variables" do
  before do
    login_as :user
  end

  describe "specific runners" do
    before do
      @project = FactoryGirl.create :project
      stub_js_gitlab_calls
    end

    it "creates variable", js: true do
      visit project_variables_path(@project)
      click_on "Add a variable"
      fill_in "Key", with: "SECRET_KEY"
      fill_in "Value", with: "SECRET_VALUE"
      click_on "Save changes"
      
      page.should have_content("Variables were successfully updated.")
      @project.variables.count.should == 1
    end

  end
end
