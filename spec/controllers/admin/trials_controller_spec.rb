require 'spec_helper'

describe Admin::TrialsController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'POST #create' do
    context 'without an active license' do
      before do
        expect_any_instance_of(License).to receive(:active?).and_return(false)
      end

      context 'with a successful response from subscription endpoint' do
        it 'redirects to the license detail page' do
          allow_any_instance_of(described_class).to receive(:save_license).and_return(true)

          post :create

          expect(response).to redirect_to admin_license_path
          expect(flash[:notice]).to eq('Your trial license was successfully activated')
        end
      end

      context 'with a failing response from subscription endpoint' do
        it 'shows an error message' do
          allow_any_instance_of(described_class).to receive(:save_license).and_return(false)

          post :create

          expect(response).to render_template(:new)
          expect(flash[:alert]).to match(/An error occurred while generating the trial license/)
        end
      end
    end

    context 'with an active license' do
      before do
        expect_any_instance_of(License).to receive(:active?).and_return(true)
      end

      it 'does not allow creating a trial license' do
        post :create

        expect(response).to redirect_to admin_license_url
        expect(flash[:alert]).to match(/You already have an active license/)
      end
    end
  end
end
