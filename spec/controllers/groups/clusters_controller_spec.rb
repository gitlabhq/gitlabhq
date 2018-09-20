# frozen_string_literal: true

require 'spec_helper'

describe Groups::ClustersController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET index' do
    describe 'functionality' do
      context 'when project does not have a cluster' do
        it 'returns an empty state page' do
          get :index, group_id: group

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index, partial: :empty_state)
          expect(assigns(:clusters)).to eq([])
        end
      end
    end
  end
end
