require 'spec_helper'

describe 'Project deploy keys', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  describe 'removing key' do
    before do
      create(:deploy_keys_project, project: project)
    end

    it 'removes association between project and deploy key' do
      visit namespace_project_settings_repository_path(project.namespace, project)

      page.within '.deploy-keys' do
        expect { click_on 'Remove' }
          .to change { project.deploy_keys.count }.by(-1)
      end
    end
  end
end
