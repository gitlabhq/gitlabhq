require 'spec_helper'

describe LicenseHelper do
  describe '#license_message' do
    context 'no license installed' do
      before do
        allow(License).to receive(:current).and_return(nil)
      end

      context 'admin user' do
        let(:is_admin) { true }

        it 'displays correct error message for admin user' do
          admin_msg = '<p>No GitLab Enterprise Edition license has been provided yet. Pushing code and creation of issues and merge requests has been disabled. <a href="/admin/license/new">Upload a license</a> in the admin area to activate this functionality.</p>'

          expect(license_message(signed_in: true, is_admin: is_admin)).to eq(admin_msg)
        end
      end

      context 'normal user' do
        let(:is_admin) { false }
        it 'displays correct error message for normal user' do
          user_msg = '<p>No GitLab Enterprise Edition license has been provided yet. Pushing code and creation of issues and merge requests has been disabled. Ask an admin to upload a license to activate this functionality.</p>'

          expect(license_message(signed_in: true, is_admin: is_admin)).to eq(user_msg)
        end
      end
    end
  end
end
