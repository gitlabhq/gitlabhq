require 'spec_helper'

describe Admin::LicensesController do
  let(:admin) { create(:admin) }
  before { sign_in(admin) }

  describe 'Upload license' do
    it 'redirects back when no license is entered/uploaded' do
      post :create, license: { data: '' }

      expect(response).to redirect_to new_admin_license_path
      expect(flash[:alert]).to include 'Please enter or upload a license.'
    end
  end
end
