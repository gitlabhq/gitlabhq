require 'spec_helper'

describe "Projects", feature: true, js: true do
  before { login_as :user }

  describe "DELETE /projects/:id" do
    before do
      @project = create(:project, namespace: @user.namespace)
      @project.team << [@user, :master]
      visit edit_project_path(@project)
    end

    it "should remove project" do
      expect { remove_project }.to change {Project.count}.by(-1)
    end

    it 'should delete the project from disk' do
      expect(GitlabShellWorker).to(
        receive(:perform_async).with(:remove_repository,
                                     /#{@project.path_with_namespace}/)
      ).twice

      remove_project
    end
  end

  def remove_project
    click_link "Remove project"
    fill_in 'confirm_name_input', with: @project.path
    click_button 'Confirm'
  end
end
