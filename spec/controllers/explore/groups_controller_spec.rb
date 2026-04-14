# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::GroupsController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#index' do
    context 'when html format' do
      render_views

      it 'renders index template' do
        get :index

        expect(response).to render_template('explore/groups/index')
      end
    end

    context 'when json format' do
      it 'only includes public and internal groups', :aggregate_failures do
        private_group = create(:group, :private, developers: [user])
        internal_group = create(:group, :internal)
        public_group = create(:group, :public)

        get :index, format: :json

        expect(response).to have_gitlab_http_status(:ok)

        group_ids = json_response.pluck('id')
        expect(group_ids).to include(internal_group.id, public_group.id)
        expect(group_ids).not_to include(private_group.id)
      end

      it_behaves_like 'groups controller with active parameter'
    end

    context 'when restricted visibility level is public' do
      before do
        sign_out(user)

        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'redirects to login page' do
        get :index

        expect(response).to redirect_to new_user_session_path
      end
    end
  end
end
