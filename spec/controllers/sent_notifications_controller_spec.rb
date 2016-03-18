require 'rails_helper'

describe SentNotificationsController, type: :controller do
  let(:user)              { create(:user) }
  let(:issue)             { create(:issue, author: user) }
  let(:sent_notification) { create(:sent_notification, noteable: issue) }

  describe 'GET #unsubscribe' do
    it 'returns a 404 when calling without existing id' do
      get(:unsubscribe, id: '0' * 32)

      expect(response.status).to be 404
    end

    context 'calling with id' do
      it 'shows a flash message to the user' do
        get(:unsubscribe, id: sent_notification.reply_key)

        expect(response.status).to be 302

        expect(response).to redirect_to new_user_session_path
        expect(controller).to set_flash[:notice].to(/unsubscribed/).now
      end
    end
  end
end
