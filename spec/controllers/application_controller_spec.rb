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

  describe 'check labels authorization' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:controller) { ApplicationController.new }

    before do
      project.team << [user, :guest]
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:project).and_return(project)
    end

    it 'should succeed if issues and MRs are enabled' do
      project.issues_enabled = true
      project.merge_requests_enabled = true
      controller.send(:authorize_read_label!)
      expect(response.status).to eq(200)
    end

    it 'should succeed if issues are enabled, MRs are disabled' do
      project.issues_enabled = true
      project.merge_requests_enabled = false
      controller.send(:authorize_read_label!)
      expect(response.status).to eq(200)
    end

    it 'should succeed if issues are disabled, MRs are enabled' do
      project.issues_enabled = false
      project.merge_requests_enabled = true
      controller.send(:authorize_read_label!)
      expect(response.status).to eq(200)
    end

    it 'should fail if issues and MRs are disabled' do
      project.issues_enabled = false
      project.merge_requests_enabled = false
      expect(controller).to receive(:access_denied!)
      controller.send(:authorize_read_label!)
    end
  end
end
