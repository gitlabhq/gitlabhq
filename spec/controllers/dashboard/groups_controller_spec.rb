require 'spec_helper'

describe Dashboard::GroupsController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'renders group trees' do
    expect(described_class).to include(GroupTree)
  end

  it 'only includes projects the user is a member of' do
    member_of_group = create(:group)
    member_of_group.add_developer(user)
    create(:group, :public)

    get :index

    expect(assigns(:groups)).to contain_exactly(member_of_group)
  end

  context 'when rendering an expanded hierarchy with public groups you are not a member of', :nested_groups do
    let!(:top_level_result) { create(:group, name: 'chef-top') }
    let!(:top_level_a) { create(:group, name: 'top-a') }
    let!(:sub_level_result_a) { create(:group, name: 'chef-sub-a', parent: top_level_a) }
    let!(:other_group) { create(:group, name: 'other') }

    before do
      top_level_result.add_master(user)
      top_level_a.add_master(user)
    end

    it 'renders only groups the user is a member of when searching hierarchy correctly' do
      get :index, filter: 'chef', format: :json

      expect(response).to have_gitlab_http_status(200)
      all_groups = [top_level_result, top_level_a, sub_level_result_a]
      expect(assigns(:groups)).to contain_exactly(*all_groups)
    end
  end
end
