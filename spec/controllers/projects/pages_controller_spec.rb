# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PagesController, feature_category: :pages do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project
    }
  end

  before do
    stub_config(pages: {
      enabled: true,
      external_https: true,
      access_control: false
    })

    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET new' do
    it 'returns 200 status' do
      get :new, params: request_params

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the project is in a subgroup' do
      let(:group) { create(:group, :nested) }
      let(:project) { create(:project, namespace: group) }

      it 'returns a 200 status code' do
        get :new, params: request_params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET show' do
    subject { get :show, params: request_params }

    context 'when the project does not have onboarding complete' do
      before do
        project.pages_metadatum.update_attribute(:onboarding_complete, false)
      end

      it 'redirects to #new' do
        expect(subject).to redirect_to(action: 'new')
      end
    end

    context 'when the project does have onboarding complete' do
      before do
        project.pages_metadatum.update_attribute(:onboarding_complete, true)
      end

      it 'returns 200 status' do
        expect(subject).to have_gitlab_http_status(:ok)
      end

      context 'when the project is in a subgroup' do
        let(:group) { create(:group, :nested) }
        let(:project) { create(:project, namespace: group) }

        it 'returns a 200 status code' do
          expect(subject).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when the project has a deployed pages app' do
      before do
        project.pages_metadatum.update_attribute(:onboarding_complete, false)
        create(:pages_deployment, project: project)
      end

      it 'does not redirect to #new' do
        expect(subject).not_to redirect_to(action: 'new')
      end
    end

    context 'when pages is disabled' do
      let(:project) { create(:project, :pages_disabled) }

      it 'renders the disabled view' do
        expect(subject).to render_template :disabled
      end
    end
  end

  describe 'DELETE destroy' do
    it 'returns 302 status' do
      delete :destroy, params: request_params

      expect(response).to have_gitlab_http_status(:found)
    end

    context 'when user is developer' do
      before do
        project.add_developer(user)
      end

      it 'returns 404 status' do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'pages disabled' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
    end

    describe 'GET show' do
      it 'returns 404 status' do
        get :show, params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'DELETE destroy' do
      it 'returns 404 status' do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PATCH update' do
    context 'when updating pages_https_only' do
      let(:request_params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          project: { pages_https_only: 'true' }
        }
      end

      it 'updates project field and redirects back to the pages settings' do
        project.update!(pages_https_only: false)

        expect { patch :update, params: request_params }
          .to change { project.reload.pages_https_only }
          .from(false).to(true)

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_pages_path(project))
      end

      context 'when it fails to update' do
        it 'adds an error message' do
          expect_next_instance_of(Projects::UpdateService) do |service|
            expect(service)
              .to receive(:execute)
              .and_return(status: :error, message: 'some error happened')
          end

          expect { patch :update, params: request_params }
            .not_to change { project.reload.pages_https_only }

          expect(response).to redirect_to(project_pages_path(project))
          expect(flash[:alert]).to eq('some error happened')
        end
      end
    end

    context 'when updating pages_unique_domain' do
      let(:request_params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          project: {
            project_setting_attributes: {
              pages_unique_domain_enabled: 'true'
            }
          }
        }
      end

      before do
        create(:project_setting, project: project, pages_unique_domain_enabled: false)
      end

      it 'updates pages_https_only and pages_unique_domain and redirects back to pages settings' do
        expect { patch :update, params: request_params }
          .to change { project.project_setting.reload.pages_unique_domain_enabled }
          .from(false).to(true)

        expect(project.project_setting.pages_unique_domain).not_to be_nil
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_pages_path(project))
      end

      context 'when it fails to update' do
        it 'adds an error message' do
          expect_next_instance_of(Projects::UpdateService) do |service|
            expect(service)
              .to receive(:execute)
              .and_return(status: :error, message: 'some error happened')
          end

          expect { patch :update, params: request_params }
            .not_to change { project.project_setting.reload.pages_unique_domain_enabled }

          expect(response).to redirect_to(project_pages_path(project))
          expect(flash[:alert]).to eq('some error happened')
        end
      end
    end
  end
end
