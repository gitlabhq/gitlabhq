require 'spec_helper'

describe "Projects", feature: true  do
  before { login_as :user }

  describe "DELETE /projects/:id" do
    before do
      @project = create(:project, namespace: @user.namespace)
      @project.team << [@user, :master]
      visit edit_project_path(@project)
    end

    it "should be correct path" do
      expect { click_link "Remove project" }.to change {Project.count}.by(-1)
    end
  end
end
