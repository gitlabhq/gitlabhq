require 'spec_helper'

describe Groups::NotificationSettingsController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  describe '#update' do
    context 'when not authorized' do
      it 'redirects to sign in page' do
        put :update,
            group_id: group.to_param,
            notification_setting: { level: :participating }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authorized' do
      before do
        sign_in(user)
      end

      it 'returns success' do
        put :update,
            group_id: group.to_param,
            notification_setting: { level: :participating }

        expect(response.status).to eq 200
      end
    end
  end
end
