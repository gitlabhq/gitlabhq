# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::GroupsController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when `explore_groups_vue` flag is enabled' do
    render_views

    before do
      stub_feature_flags(explore_groups_vue: true)
    end

    it 'pushes explore_groups_vue feature flag' do
      get :index

      expect(response.body).to have_pushed_frontend_feature_flags(exploreGroupsVue: true)
      expect(response).to render_template('explore/groups/index')
    end
  end

  context 'when `explore_groups_vue` flag is disabled' do
    before do
      stub_feature_flags(explore_groups_vue: false)
    end

    shared_examples 'explore groups' do
      it 'renders group trees' do
        expect(described_class).to include(GroupTree)
      end

      it 'only includes public and internal groups', :aggregate_failures do
        private_group = create(:group, :private, developers: [user])
        internal_group = create(:group, :internal)
        public_group = create(:group, :public)

        get :index

        expect(assigns(:groups)).to include(internal_group, public_group)
        expect(assigns(:groups)).not_to include(private_group)
      end

      context 'when `explore_groups_non_members_only` is disabled' do
        before do
          stub_feature_flags(explore_groups_non_members_only: false)
        end

        it 'includes member private groups' do
          member_of_group = create(:group, :private, developers: [user])
          internal_group = create(:group, :internal)
          public_group = create(:group, :public)

          get :index

          expect(assigns(:groups)).to contain_exactly(member_of_group, internal_group, public_group)
        end
      end

      context 'restricted visibility level is public' do
        before do
          sign_out(user)

          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it 'redirects to login page' do
          get :index

          expect(response).to redirect_to new_user_session_path
        end
      end

      it_behaves_like 'groups controller with active parameter'
    end

    it_behaves_like 'explore groups'

    context 'gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it_behaves_like 'explore groups'
    end
  end
end
