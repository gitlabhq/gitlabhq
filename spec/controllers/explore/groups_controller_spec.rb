require 'spec_helper'

describe Explore::GroupsController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'renders group trees' do
    expect(described_class).to include(GroupTree)
  end

  it 'includes public projects' do
    member_of_group = create(:group)
    member_of_group.add_developer(user)
    public_group = create(:group, :public)

    get :index

    expect(assigns(:groups)).to contain_exactly(member_of_group, public_group)
  end
end
