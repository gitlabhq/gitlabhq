# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::AvatarsController do
  let(:user) { create(:user, avatar: fixture_file_upload("spec/fixtures/dk.png")) }

  before do
    sign_in(user)
    controller.instance_variable_set(:@user, user)
  end

  it 'removes avatar from DB by calling destroy' do
    delete :destroy
    @user = assigns(:user)
    expect(@user.avatar.present?).to be_falsey
    expect(@user).to be_valid
  end
end
