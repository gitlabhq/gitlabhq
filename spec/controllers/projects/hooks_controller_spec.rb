require 'spec_helper'

describe Projects::HooksController do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe '#index' do
    it 'redirects to settings/integrations page' do
      get(:index, namespace_id: project.namespace, project_id: project)

      expect(response).to redirect_to(
        project_settings_integrations_path(project)
      )
    end
  end
end
