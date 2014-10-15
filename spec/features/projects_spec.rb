require 'spec_helper'

describe "Projects", feature: true  do
  before { login_as :user }

  describe "DELETE /projects/:id" do
    before do
      @project = create(:project, namespace: @user.namespace)
      @project.team << [@user, :master]
      visit edit_project_path(@project)
    end

    it "should be correct path", js: true do
      expect {
        click_link "Remove project"
        fill_in 'confirm_name_input', with: @project.path
        click_button 'Confirm'
      }.to change {Project.count}.by(-1)
    end
  end
end
