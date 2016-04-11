require 'spec_helper'

describe Groups::NotificationSettingsController do
  let(:group) { create(:group) }

  describe '#update' do
    context 'when not authorized' do
      it 'redirects to sign in page' do
        put :update,
            group_id: group.to_param,
            notification_setting: { level: NotificationSetting.levels[:participating] }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
