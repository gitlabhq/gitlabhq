require 'spec_helper'

describe NotificationSettingsController do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :developer]
  end

  describe '#create' do
    context 'when not authorized' do
      it 'redirects to sign in page' do
        post :create,
             project: { id: project.id },
             notification_setting: { level: :participating }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authorized' do
      before do
        sign_in(user)
      end

      it 'returns success' do
        post :create,
             project: { id: project.id },
             notification_setting: { level: :participating }

        expect(response.status).to eq 200
      end

      context 'and setting custom notification setting' do
        let(:custom_events) do
          events = {}

          NotificationSetting::EMAIL_EVENTS.each do |event|
            events[event] = "true"
          end
        end

        it 'returns success' do
          post :create,
               project: { id: project.id },
               notification_setting: { level: :participating, events: custom_events }

          expect(response.status).to eq 200
        end
      end
    end

    context 'not authorized' do
      let(:private_project) { create(:project, :private) }
      before { sign_in(user) }

      it 'returns 404' do
        post :create,
             project: { id: private_project.id },
             notification_setting: { level: :participating }

        expect(response.status).to eq(404)
      end
    end
  end

  describe '#update' do
    let(:notification_setting) { user.global_notification_setting }

    context 'when not authorized' do
      it 'redirects to sign in page' do
        put :update,
            id: notification_setting,
            notification_setting: { level: :participating }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authorized' do
      before{ sign_in(user) }

      it 'returns success' do
        put :update,
            id: notification_setting,
            notification_setting: { level: :participating }

        expect(response.status).to eq 200
      end

      context 'and setting custom notification setting' do
        let(:custom_events) do
          events = {}

          NotificationSetting::EMAIL_EVENTS.each do |event|
            events[event] = "true"
          end
        end

        it 'returns success' do
          put :update,
              id: notification_setting,
              notification_setting: { level: :participating, events: custom_events }

          expect(response.status).to eq 200
        end
      end
    end

    context 'not authorized' do
      let(:other_user) { create(:user) }

      before { sign_in(other_user) }

      it 'returns 404' do
        put :update,
            id: notification_setting,
            notification_setting: { level: :participating }

        expect(response.status).to eq(404)
      end
    end
  end
end
