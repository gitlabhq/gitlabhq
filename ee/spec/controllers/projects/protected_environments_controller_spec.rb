# frozen_string_literal: true
require 'spec_helper'

describe Projects::ProtectedEnvironmentsController do
  let(:project) { create(:project) }
  let(:current_user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }

  before do
    sign_in(current_user)
  end

  describe '#POST create' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ access_level: maintainer_access }])
    end

    subject do
      post :create,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        protected_environment: params
    end

    context 'with valid access and params' do
      before do
        project.add_maintainer(current_user)
      end

      context 'with valid params' do
        it 'should create a new ProtectedEnvironment' do
          expect do
            subject
          end.to change(ProtectedEnvironment, :count).by(1)
        end

        it 'should set a flash' do
          subject

          expect(controller).to set_flash[:notice].to(/environment has been protected/)
        end

        it 'should redirect to CI/CD settings' do
          subject

          expect(response).to redirect_to project_settings_ci_cd_path(project)
        end
      end

      context 'with invalid params' do
        let(:params) do
          attributes_for(:protected_environment,
                         name: '',
                         deploy_access_levels_attributes: [{ access_level: maintainer_access }])
        end

        it 'should not create a new ProtectedEnvironment' do
          expect do
            subject
          end.not_to change(ProtectedEnvironment, :count)
        end

        it 'should redirect to CI/CD settings' do
          subject

          expect(response).to redirect_to project_settings_ci_cd_path(project)
        end
      end
    end

    context 'with invalid access' do
      before do
        project.add_developer(current_user)
      end

      it 'should render 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe '#PUT update' do
    let(:protected_environment) { create(:protected_environment, project: project) }
    let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

    let(:params) do
      {
        deploy_access_levels_attributes: [
          { id: deploy_access_level.id, access_level: Gitlab::Access::DEVELOPER },
          { access_level: maintainer_access }
        ]
      }
    end

    subject do
      put :update,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        id: protected_environment.id,
        protected_environment: params
    end

    context 'when the user is authorized' do
      before do
        project.add_maintainer(current_user)

        subject
      end

      it 'should find the requested protected environment' do
        expect(assigns(:protected_environment)).to eq(protected_environment)
      end

      it 'should update the protected environment' do
        expect(protected_environment.deploy_access_levels.count).to eq(2)
      end

      it 'should be success' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when the user is not authorized' do
      before do
        project.add_developer(current_user)

        subject
      end

      it 'should not be success' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe '#DELETE destroy' do
    let!(:protected_environment) { create(:protected_environment, project: project) }

    subject do
      delete :destroy,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        id: protected_environment.id
    end

    context 'when the user is authorized' do
      before do
        project.add_maintainer(current_user)
      end

      it 'should find the requested protected environment' do
        subject

        expect(assigns(:protected_environment)).to eq(protected_environment)
      end

      it 'should delete the requested protected environment' do
        expect do
          subject
        end.to change { ProtectedEnvironment.count }.from(1).to(0)
      end

      it 'should redirect to CI/CD settings' do
        subject

        expect(response).to redirect_to project_settings_ci_cd_path(project)
      end
    end

    context 'when the user is not authorized' do
      before do
        project.add_developer(current_user)
      end

      it 'should not be success' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
