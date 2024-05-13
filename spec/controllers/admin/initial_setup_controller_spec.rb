# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::InitialSetupController, feature_category: :system_access do
  let!(:admin) { create(:admin, username: 'root', password_automatically_set: true) }

  shared_examples 'gated by initial setup state' do
    before do
      allow(controller).to receive(:in_initial_setup_state?).and_return(false)
    end

    it 'redirects if not in initial setup state' do
      subject

      expect(response).to redirect_to(root_path)
    end
  end

  describe '#new' do
    subject(:get_new) { get :new }

    it 'renders new page' do
      get_new

      expect(response).to render_template(:new)
    end

    it_behaves_like 'gated by initial setup state'
  end

  describe '#update' do
    subject(:patch_update) { post :update, params: { user: user_params } }

    context 'with valid params' do
      let(:user_params) do
        {
          email: 'capybara@example.com',
          password: 'GiantHamsterD0g!',
          password_confirmation: 'GiantHamsterD0g!'
        }
      end

      it 'redirects to sign in page' do
        patch_update

        expect(response).to redirect_to(new_user_session_path)

        expect(admin.reload.email).to eq(user_params[:email])
        expect(admin.emails.count).to eq(1)
        expect(admin.emails.first).to be_user_primary_email

        expect(admin.valid_password?('GiantHamsterD0g!')).to be(true)
      end

      it_behaves_like 'gated by initial setup state'
    end

    context 'with invalid password' do
      let(:user_params) do
        {
          email: 'capybara@example.com',
          password: '1',
          password_confirmation: '1'
        }
      end

      it 'renders form with errors and does not update user' do
        expect { patch_update }.not_to change { admin.reload.email }

        expect(response).to render_template(:new)
        expect(admin.valid_password?('1')).to be(false)
      end
    end

    context 'with invalid email' do
      let(:user_params) do
        {
          email: 'invalid capybara email @ example dotcom',
          password: 'GiantHamsterD0g!',
          password_confirmation: 'GiantHamsterD0g!'
        }
      end

      it 'renders form with errors and does not update user' do
        expect { patch_update }.not_to change { admin.reload.email }

        expect(response).to render_template(:new)
        expect(admin.valid_password?('GiantHamsterD0g!')).to be(false)
      end
    end
  end
end
