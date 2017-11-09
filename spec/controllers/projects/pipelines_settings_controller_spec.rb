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
          auto_devops_attributes: params
        }
    end

    context 'when updating the auto_devops settings' do
      let(:params) { { enabled: '', domain: 'mepmep.md' } }

      it 'redirects to the settings page' do
        expect(response).to have_gitlab_http_status(302)
        expect(flash[:notice]).to eq("Pipelines settings for '#{project.name}' were successfully updated.")
      end

      context 'following the instance default' do
        let(:params) { { enabled: '' } }

        it 'allows enabled to be set to nil' do
          project_auto_devops.reload

          expect(project_auto_devops.enabled).to be_nil
        end
      end
    end
  end
end
