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
end
