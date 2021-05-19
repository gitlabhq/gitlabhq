# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::ValueStreamsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:params) { { namespace_id: group, project_id: project } }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    context 'when user is member of the project' do
      before do
        project.add_developer(user)
      end

      it 'succeeds' do
        get :index, params: params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'exposes the default value stream' do
        get :index, params: params

        expect(json_response.first['name']).to eq('default')
      end
    end

    context 'when user is not member of the project' do
      it 'renders 404' do
        get :index, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
