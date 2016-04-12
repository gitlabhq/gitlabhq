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
    end
  end
end
