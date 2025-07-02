# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupTree, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public, owners: [user]) }

  controller(ApplicationController) do
    # `described_class` is not available in this context
    include GroupTree

    def index
      render_group_tree GroupsFinder.new(current_user, active: safe_params[:active]).execute
    end
  end

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    shared_examples 'returns filtered groups' do
      it 'filters groups' do
        other_group = create(:group, name: 'filter')
        other_group.add_owner(user)

        get :index, params: { filter: 'filt' }, format: :json

        expect(assigns(:groups)).to contain_exactly(other_group)
      end

      context 'for subgroups' do
        it 'only renders root groups when no parent was given' do
          create(:group, :public, parent: group)

          get :index, format: :json

          expect(assigns(:groups)).to contain_exactly(group)
        end

        it 'contains only the subgroup when a parent was given' do
          subgroup = create(:group, :public, parent: group)

          get :index, params: { parent_id: group.id }, format: :json

          expect(assigns(:groups)).to contain_exactly(subgroup)
        end

        it 'allows filtering for subgroups and includes the parents for rendering' do
          subgroup = create(:group, :public, parent: group, name: 'filter')

          get :index, params: { filter: 'filt' }, format: :json

          expect(assigns(:groups)).to contain_exactly(group, subgroup)
        end

        it 'does not include groups the user does not have access to' do
          parent = create(:group, :private)
          subgroup = create(:group, :private, parent: parent, name: 'filter')
          subgroup.add_developer(user)
          _other_subgroup = create(:group, :private, parent: parent, name: 'filte')

          get :index, params: { filter: 'filt' }, format: :json

          expect(assigns(:groups)).to contain_exactly(parent, subgroup)
        end

        it 'preloads parents regardless of pagination' do
          allow(Kaminari.config).to receive(:default_per_page).and_return(1)
          group = create(:group, :public)
          subgroup = create(:group, :public, parent: group)
          search_result = create(:group, :public, name: 'result', parent: subgroup)

          get :index, params: { filter: 'resu' }, format: :json

          expect(assigns(:groups)).to contain_exactly(group, subgroup, search_result)
        end
      end

      context 'with active parameter' do
        let_it_be(:active_ancestor) { group }
        let_it_be(:inactive_ancestor) { create(:group, :archived, :public) }
        let_it_be(:active_child) { create(:group, parent: active_ancestor) }
        let_it_be(:inactive_child) { create(:group, parent: inactive_ancestor) }

        context 'when true' do
          it 'only loads root group' do
            allow(GroupsFinder).to receive(:execute).and_return(Group.where(id: active_child.id))

            get :index, params: { active: true }, format: :json

            expect(assigns(:groups)).to include(active_ancestor)
            expect(assigns(:groups)).not_to include(active_child, inactive_ancestor, inactive_child)
          end
        end

        context 'when false' do
          it 'preloads inactive ancestors' do
            allow(GroupsFinder).to receive(:execute).and_return(Group.where(id: inactive_child.id))

            get :index, params: { active: false }, format: :json

            expect(assigns(:groups)).to include(inactive_ancestor, inactive_child)
            expect(assigns(:groups)).not_to include(active_ancestor, active_child)
          end
        end
      end

      context 'json content' do
        it 'shows groups as json' do
          get :index, format: :json

          expect(json_response.first['id']).to eq(group.id)
        end

        context 'nested groups' do
          it 'expands the tree when filtering' do
            subgroup = create(:group, :public, parent: group, name: 'filter')

            get :index, params: { filter: 'filt' }, format: :json

            children_response = json_response.first['children']

            expect(json_response.first['id']).to eq(group.id)
            expect(children_response.first['id']).to eq(subgroup.id)
          end
        end
      end
    end

    it_behaves_like 'returns filtered groups'
  end
end
