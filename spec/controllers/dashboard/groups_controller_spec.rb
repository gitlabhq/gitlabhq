require 'spec_helper'

describe Dashboard::GroupsController do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'shows child groups as json' do
      get :index, format: :json

      expect(json_response.first['id']).to eq(group.id)
    end

    it 'filters groups' do
      other_group = create(:group, name: 'filter')
      other_group.add_owner(user)

      get :index, filter: 'filt', format: :json
      all_ids = json_response.map { |group_json| group_json['id'] }

      expect(all_ids).to contain_exactly(other_group.id)
    end
  end
end
