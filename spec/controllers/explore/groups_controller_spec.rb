# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::GroupsController do
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
end
