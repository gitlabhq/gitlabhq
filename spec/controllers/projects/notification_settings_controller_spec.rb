require 'spec_helper'

describe Projects::NotificationSettingsController do
  let(:project) { create(:empty_project) }

  describe '#create' do
    context 'when not authorized' do
      it 'redirects to sign in page' do
        post :create,
             namespace_id: project.namespace.to_param,
             project_id: project.to_param,
             notification_setting: { level: NotificationSetting.levels[:participating] }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe '#update' do
    context 'when not authorized' do
      it 'redirects to sign in page' do
        put :update,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            notification_setting: { level: NotificationSetting.levels[:participating] }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
