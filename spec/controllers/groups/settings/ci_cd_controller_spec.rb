# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::CiCdController do
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
    subject do
      patch :update, params: {
        group_id: group,
        group: { max_artifacts_size: 10 }
      }
    end

    context 'when user is not an admin' do
      before do
        group.add_owner(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user is an admin' do
      let(:user) { create(:admin) }

      before do
        group.add_owner(user)
      end

      context 'when admin mode is disabled' do
        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to redirect_to(group_settings_ci_cd_path) }

        context 'when service execution went wrong' do
          let(:update_service) { double }

          before do
            allow(Groups::UpdateService).to receive(:new).and_return(update_service)
            allow(update_service).to receive(:execute).and_return(false)
            allow_any_instance_of(Group).to receive_message_chain(:errors, :full_messages)
              .and_return(['Error 1'])

            subject
          end

          it 'returns a flash alert' do
            expect(controller).to set_flash[:alert]
              .to eq("There was a problem updating the pipeline settings: [\"Error 1\"].")
          end
        end

        context 'when service execution was successful' do
          it 'returns a flash notice' do
            subject

            expect(controller).to set_flash[:notice]
              .to eq('Pipeline settings was updated for the group')
          end
        end
      end
    end
  end
end
