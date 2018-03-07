require 'spec_helper'

describe NotificationSettingsController do
  let(:project) { create(:project) }
  let(:group) { create(:group, :internal) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
  end

  describe '#create' do
    context 'when not authorized' do
      it 'redirects to sign in page' do
        post :create,
             project_id: project.id,
             notification_setting: { level: :participating }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authorized' do
      let(:custom_events) do
        events = {}

        NotificationSetting::EMAIL_EVENTS.each do |event|
          events[event.to_s] = true
        end

        events
      end

      before do
        sign_in(user)
      end

      context 'for projects' do
        let(:notification_setting) { user.notification_settings_for(project) }

        it 'creates notification setting' do
          post :create,
               project_id: project.id,
               notification_setting: { level: :participating }

          expect(response.status).to eq 200
          expect(notification_setting.level).to eq("participating")
          expect(notification_setting.user_id).to eq(user.id)
          expect(notification_setting.source_id).to eq(project.id)
          expect(notification_setting.source_type).to eq("Project")
        end

        context 'with custom settings' do
          it 'creates notification setting' do
            post :create,
                 project_id: project.id,
                 notification_setting: { level: :custom }.merge(custom_events)

            expect(response.status).to eq 200
            expect(notification_setting.level).to eq("custom")

            custom_events.each do |event, value|
              expect(notification_setting.event_enabled?(event)).to eq(value)
            end
          end
        end
      end

      context 'for groups' do
        let(:notification_setting) { user.notification_settings_for(group) }

        it 'creates notification setting' do
          post :create,
               namespace_id: group.id,
               notification_setting: { level: :watch }

          expect(response.status).to eq 200
          expect(notification_setting.level).to eq("watch")
          expect(notification_setting.user_id).to eq(user.id)
          expect(notification_setting.source_id).to eq(group.id)
          expect(notification_setting.source_type).to eq("Namespace")
        end

        context 'with custom settings' do
          it 'creates notification setting' do
            post :create,
                 namespace_id: group.id,
                 notification_setting: { level: :custom }.merge(custom_events)

            expect(response.status).to eq 200
            expect(notification_setting.level).to eq("custom")

            custom_events.each do |event, value|
              expect(notification_setting.event_enabled?(event)).to eq(value)
            end
          end
        end
      end
    end

    context 'not authorized' do
      let(:private_project) { create(:project, :private) }

      before do
        sign_in(user)
      end

      it 'returns 404' do
        post :create,
             project_id: private_project.id,
             notification_setting: { level: :participating }

        expect(response).to have_gitlab_http_status(404)
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
      before do
        sign_in(user)
      end

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

      before do
        sign_in(other_user)
      end

      it 'returns 404' do
        put :update,
            id: notification_setting,
            notification_setting: { level: :participating }

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
