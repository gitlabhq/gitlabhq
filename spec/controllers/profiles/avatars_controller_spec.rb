require 'spec_helper'

describe Profiles::AvatarsController do
  let(:user)    { create(:user, :with_avatar) }

  before do
    sign_in(user)
    controller.instance_variable_set(:@user, user)
  end

  it 'destroy should remove avatar from DB' do
    delete :destroy
    @user = assigns(:user)
    expect(@user.avatar.present?).to be_falsey
    expect(@user).to be_valid
  end
end
