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
          expect(license_message(signed_in: true, is_admin: is_admin)).to be_blank
        end
      end

      context 'normal user' do
        let(:is_admin) { false }
        it 'displays correct error message for normal user' do
          expect(license_message(signed_in: true, is_admin: is_admin)).to be_blank
        end
      end
    end
  end
end
