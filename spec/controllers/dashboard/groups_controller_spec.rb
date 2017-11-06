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
end
