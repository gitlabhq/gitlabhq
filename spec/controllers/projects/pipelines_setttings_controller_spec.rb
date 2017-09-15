require 'spec_helper'

describe Projects::PipelinesSettingsController do
  set(:user) { create(:user) }
  set(:project_auto_devops) { create(:project_auto_devops) }
  let(:project) { project_auto_devops.project }

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe 'PATCH update' do
    before do
      patch :update,
        namespace_id: project.namespace.to_param,
        project_id: project,
        project: {
          auto_devops_attributes: { enabled: false, domain: 'mempmep.md' }
        }
    end

    context 'when updating the auto_devops settings' do
      it 'redirects to the settings page' do
        expect(response).to have_http_status(302)
        expect(flash[:notice]).to eq("Pipelines settings for '#{project.name}' were successfully updated.")
      end
    end
  end
end
