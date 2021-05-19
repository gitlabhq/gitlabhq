# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::StagesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:params) { { namespace_id: group, project_id: project, value_stream_id: 'default' } }

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

      it 'exposes the default stages' do
        get :index, params: params

        expect(json_response['stages'].size).to eq(Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size)
      end

      context 'when list service fails' do
        it 'renders 403' do
          expect_next_instance_of(Analytics::CycleAnalytics::Stages::ListService) do |list_service|
            expect(list_service).to receive(:allowed?).and_return(false)
          end

          get :index, params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when invalid value stream id is given' do
      before do
        params[:value_stream_id] = 1
      end

      it 'renders 404' do
        get :index, params: params

        expect(response).to have_gitlab_http_status(:not_found)
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
