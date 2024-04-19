# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::CiCdController, feature_category: :continuous_integration do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'external authorization' do
      before do
        enable_external_authorization_service_check
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'PATCH #update_auto_devops' do
    let(:auto_devops_param) { '1' }

    subject do
      patch :update_auto_devops, params: {
        group_id: group,
        group: { auto_devops_enabled: auto_devops_param }
      }
    end

    context 'when user does not have enough permission' do
      before do
        group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user has enough privileges' do
      before do
        group.add_owner(user)
      end

      it { is_expected.to redirect_to(group_settings_ci_cd_path) }

      context 'when service execution went wrong' do
        before do
          allow_any_instance_of(Groups::AutoDevopsService).to receive(:execute).and_return(false)
          allow_any_instance_of(Group).to receive_message_chain(:errors, :full_messages)
            .and_return(['Error 1'])

          subject
        end

        it 'returns a flash alert' do
          expect(controller).to set_flash[:alert]
            .to eq("There was a problem updating Auto DevOps pipeline: [\"Error 1\"].")
        end
      end

      context 'when service execution was successful' do
        it 'returns a flash notice' do
          subject

          expect(controller).to set_flash[:notice]
            .to eq('Auto DevOps pipeline was updated for the group')
        end
      end

      context 'when changing auto devops value' do
        before do
          subject

          group.reload
        end

        context 'when explicitly enabling auto devops' do
          it 'updates group attribute' do
            expect(group.auto_devops_enabled).to eq(true)
          end
        end

        context 'when explicitly disabling auto devops' do
          let(:auto_devops_param) { '0' }

          it 'updates group attribute' do
            expect(group.auto_devops_enabled).to eq(false)
          end
        end
      end
    end
  end

  describe 'PATCH #update' do
    subject(:response) { perform_request }

    def perform_request
      patch :update, params: params
    end

    context 'when user is a group owner' do
      before_all do
        group.add_owner(user)
      end

      context 'when updating max_artifacts_size' do
        let(:params) { { group_id: group, group: { max_artifacts_size: 10 } } }

        it 'cannot update max_artifacts_size' do
          expect { perform_request }.not_to change { group.reload.max_artifacts_size }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when updating allow_runner_registration_token' do
        let(:params) { { group_id: group, group: { allow_runner_registration_token: false } } }

        it 'can update allow_runner_registration_token' do
          expect { perform_request }.to change { group.reload.allow_runner_registration_token? }.from(true).to(false)
        end

        context 'when user is not a group owner' do
          before_all do
            group.add_maintainer(user)
          end

          it 'cannot update allow_runner_registration_token?' do
            expect { perform_request }.not_to change { group.reload.allow_runner_registration_token? }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'when user is a group maintainer' do
      let_it_be(:user) { create(:user).tap { |user| group.add_maintainer(user) } }

      context 'when updating allow_runner_registration_token' do
        let(:params) { { group_id: group, group: { allow_runner_registration_token: false } } }

        it 'cannot update allow_runner_registration_token?' do
          expect { perform_request }.not_to change { group.reload.allow_runner_registration_token? }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is an admin' do
      let_it_be(:user) { create(:admin).tap { |user| group.add_owner(user) } }

      context 'when admin mode is disabled' do
        context 'when updating max_artifacts_size' do
          let(:params) { { group_id: group, group: { max_artifacts_size: 10 } } }

          it { is_expected.to have_gitlab_http_status(:not_found) }
        end

        context 'when updating allow_runner_registration_token' do
          let(:params) { { group_id: group, group: { allow_runner_registration_token: false } } }

          it 'can update allow_runner_registration_token' do
            expect { perform_request }.to change { group.reload.allow_runner_registration_token? }.from(true).to(false)
          end
        end
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        let(:params) { { group_id: group, group: { max_artifacts_size: 10 } } }

        it { is_expected.to redirect_to(group_settings_ci_cd_path) }

        context 'when service execution went wrong' do
          let(:update_service) { double }

          before do
            allow(Groups::UpdateService).to receive(:new).and_return(update_service)
            allow(update_service).to receive(:execute).and_return(false)
            allow_any_instance_of(Group).to receive_message_chain(:errors, :full_messages)
              .and_return(['Error 1'])

            response
          end

          it 'returns a flash alert' do
            expect(controller).to set_flash[:alert]
              .to eq("There was a problem updating the group CI/CD settings: [\"Error 1\"].")
          end
        end

        context 'when service execution was successful' do
          it 'returns a flash notice' do
            response

            expect(controller).to set_flash[:notice]
              .to eq('Group CI/CD settings were successfully updated.')
          end
        end
      end
    end
  end
end
