require 'spec_helper'

describe LicenseHelper do
  describe '#license_message' do
    context 'no license installed' do
      before do
        expect(License).to receive(:current).and_return(nil)
      end

      it 'admin user' do
        admin_msg = '<p>No GitLab Enterprise Edition license has been provided yet. Pushing code and creation of issues and merge requests has been disabled. <a href="/admin/license/new">Upload a license</a> in the admin area to activate this functionality.</p>'

        expect(license_message(signed_in: true, is_admin: true)).to eq(admin_msg)
      end

      it 'normal user' do
        user_msg = '<p>No GitLab Enterprise Edition license has been provided yet. Pushing code and creation of issues and merge requests has been disabled. Ask an admin to upload a license to activate this functionality.</p>'

        expect(license_message(signed_in: true, is_admin: false)).to eq(user_msg)
      end
    end

    context 'license available' do
      let(:license) { create(:license) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      it 'warn for overusage' do
        allow(license).to receive(:starts_at).and_return(Time.now - 3.months)
        allow(license).to receive(:expired?).and_return(false)
        allow(license).to receive(:restricted?).and_return(true)
        allow(license).to receive(:notify_admins?).and_return(true)
        allow(license).to receive(:restrictions).and_return({ active_user_count: 50 })
        allow(User).to receive(:active).and_return(Array.new(100))

        warn_msg = 'Your GitLab license currently covers 50 users, but it looks like your site has grown to 100 users. Please contact sales@gitlab.com to increase the seats on your license. Note: This message is only visible to you as an admin.'
        expect(license_message(signed_in: true, is_admin: true)).to eq(warn_msg)
      end
    end
  end
end
