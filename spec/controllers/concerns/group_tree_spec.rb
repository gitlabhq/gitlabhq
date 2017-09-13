require 'spec_helper'

describe GroupTree do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  controller(ApplicationController) do
    include GroupTree # rubocop:disable Rspec/DescribedClass

    def index
      render_group_tree Group.all
    end
  end

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'filters groups' do
      other_group = create(:group, name: 'filter')
      other_group.add_owner(user)

      get :index, filter: 'filt', format: :json

      expect(assigns(:groups)).to contain_exactly(other_group)
    end

    context 'for subgroups', :nested_groups do
      it 'only renders root groups when no parent was given' do
        create(:group, :public, parent: group)

        get :index, format: :json

        expect(assigns(:groups)).to contain_exactly(group)
      end

      it 'contains only the subgroup when a parent was given' do
        subgroup = create(:group, :public, parent: group)

        get :index, parent_id: group.id, format: :json

        expect(assigns(:groups)).to contain_exactly(subgroup)
      end
    end

    context 'json content' do
      it 'shows groups as json' do
        get :index, format: :json

        expect(json_response.first['id']).to eq(group.id)
      end
    end
  end
end
