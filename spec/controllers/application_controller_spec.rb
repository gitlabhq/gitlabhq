require 'spec_helper'

describe ApplicationController do
  describe '#check_password_expiration' do
    let(:user) { create(:user) }
    let(:controller) { ApplicationController.new }

    it 'should redirect if the user is over their password expiry' do
      user.password_expires_at = Time.new(2002)
      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).to receive(:redirect_to)
      expect(controller).to receive(:new_profile_password_path)
      controller.send(:check_password_expiration)
    end

    it 'should not redirect if the user is under their password expiry' do
      user.password_expires_at = Time.now + 20010101
      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)
      controller.send(:check_password_expiration)
    end

    it 'should not redirect if the user is over their password expiry but they are an ldap user' do
      user.password_expires_at = Time.new(2002)
      allow(user).to receive(:ldap_user?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)
      controller.send(:check_password_expiration)
    end
  end
end
