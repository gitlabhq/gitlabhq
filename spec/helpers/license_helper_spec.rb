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
  end

  describe '#license_usage_data' do
    it "gathers license data" do
      data = license_usage_data
      license = License.current

      expect(data[:license_md5]).to eq(Digest::MD5.hexdigest(license.data))
      expect(data[:version]).to eq(Gitlab::VERSION)
      expect(data[:licensee]).to eq(license.licensee)
      expect(data[:active_user_count]).to eq(User.active.count)
      expect(data[:licensee]).to eq(license.licensee)
      expect(data[:license_user_count]).to eq(license.user_count)
      expect(data[:license_starts_at]).to eq(license.starts_at)
      expect(data[:license_expires_at]).to eq(license.expires_at)
      expect(data[:license_add_ons]).to eq(license.add_ons)
      expect(data[:recorded_at]).to be_a(Time)
    end
  end
end
