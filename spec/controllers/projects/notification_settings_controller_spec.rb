require 'spec_helper'

describe Projects::NotificationSettingsController do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :developer]
  end

  describe '#update' do
    context 'when not authorized' do
      it 'redirects to sign in page' do
        put :update,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
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
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
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
              namespace_id: project.namespace.to_param,
              project_id: project.to_param,
              notification_setting: { level: :participating, events: custom_events }

          expect(response.status).to eq 200
        end
      end
    end

    context 'not authorized' do
      let(:private_project) { create(:project, :private) }
      before { sign_in(user) }

      it 'returns 404' do
        put :update,
            namespace_id: private_project.namespace.to_param,
            project_id: private_project.to_param,
            notification_setting: { level: :participating }

        expect(response.status).to eq(404)
      end
    end
  end
end
