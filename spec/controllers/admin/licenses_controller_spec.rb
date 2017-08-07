require 'spec_helper'

describe Admin::LicensesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'Upload license' do
    it 'redirects back when no license is entered/uploaded' do
      post :create, license: { data: '' }

      expect(response).to redirect_to new_admin_license_path
      expect(flash[:alert]).to include 'Please enter or upload a license.'
    end
  end

  describe 'GET show' do
    context 'with an existent license' do
      it 'renders the license details' do
        allow(License).to receive(:current).and_return(create(:license))

        get :show

        expect(response).to render_template(:show)
      end
    end

    context 'without a license' do
      it 'renders missing license page' do
        allow(License).to receive(:current).and_return(nil)

        get :show

        expect(response).to render_template(:missing)
      end
    end
  end
end
