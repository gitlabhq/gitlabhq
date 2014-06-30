require 'spec_helper'

describe ApplicationController do
  describe '#check_password_expiration' do
    let(:user) { create(:user) }
    let(:controller) { ApplicationController.new }

    it 'should redirect if the user is over their password expiry' do
      user.password_expires_at = Time.new(2002)
      user.ldap_user?.should be_false
      controller.stub(:current_user).and_return(user)
      controller.should_receive(:redirect_to)
      controller.should_receive(:new_profile_password_path)
      controller.send(:check_password_expiration)
    end

    it 'should not redirect if the user is under their password expiry' do
      user.password_expires_at = Time.now + 20010101
      user.ldap_user?.should be_false
      controller.stub(:current_user).and_return(user)
      controller.should_not_receive(:redirect_to)
      controller.send(:check_password_expiration)
    end

    it 'should not redirect if the user is over their password expiry but they are an ldap user' do
      user.password_expires_at = Time.new(2002)
      user.stub(:ldap_user?).and_return(true)
      controller.stub(:current_user).and_return(user)
      controller.should_not_receive(:redirect_to)
      controller.send(:check_password_expiration)
    end
  end
end
