require 'spec_helper'

describe "Variables" do
  let(:user)    { create(:user) }

  before do
    login_as(user)
  end

  describe "specific runners" do
    before do
      @project = FactoryGirl.create :ci_project
      @project.gl_project.team << [user, :master]
    end

    it "creates variable", js: true do
      visit ci_project_variables_path(@project)
      click_on "Add a variable"
      fill_in "Key", with: "SECRET_KEY"
      fill_in "Value", with: "SECRET_VALUE"
      click_on "Save changes"
      
      expect(page).to have_content("Variables were successfully updated.")
      expect(@project.variables.count).to eq(1)
    end

  end
end
