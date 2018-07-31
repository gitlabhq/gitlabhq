require 'spec_helper'

describe Admin::GroupsController do
  let(:admin) { create(:admin) }
  let(:group) { create(:group) }

  before do
    sign_in(admin)
  end

  describe 'POST #reset_runner_minutes' do
    subject { post :reset_runners_minutes, id: group }

    before do
      allow_any_instance_of(ClearNamespaceSharedRunnersMinutesService)
          .to receive(:execute).and_return(clear_runners_minutes_service_result)
    end

    context 'when the reset is successful' do
      let(:clear_runners_minutes_service_result) { true }

      it 'redirects to group path' do
        subject

        expect(response).to redirect_to(admin_group_path(group))
        expect(response).to set_flash[:notice]
      end
    end

    context 'when the reset is not successful' do
      let(:clear_runners_minutes_service_result) { false }

      it 'redirects back to group edit page' do
        subject

        expect(response).to render_template(:edit)
        expect(response).to set_flash.now[:error]
      end
    end
  end

  context 'PUT update' do
    context 'no license' do
      it 'does not update the project_creation_level successfully' do
        stub_licensed_features(project_creation_level: false)

        expect do
          post :update, id: group.to_param, group: { project_creation_level: ::EE::Gitlab::Access::NO_ONE_PROJECT_ACCESS }
        end.not_to change { group.reload.project_creation_level }
      end
    end

    context 'licensed' do
      it 'updates the project_creation_level successfully' do
        stub_licensed_features(project_creation_level: true)

        expect do
          post :update, id: group.to_param, group: { project_creation_level: ::EE::Gitlab::Access::NO_ONE_PROJECT_ACCESS }
        end.to change { group.reload.project_creation_level }.to(::EE::Gitlab::Access::NO_ONE_PROJECT_ACCESS)
      end
    end
  end
end
