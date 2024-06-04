# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupTree, feature_category: :groups_and_projects do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  controller(ApplicationController) do
    # `described_class` is not available in this context
    include GroupTree

    def index
      render_group_tree GroupsFinder.new(current_user).execute
    end
  end

  before do
    group.add_owner(user)
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
