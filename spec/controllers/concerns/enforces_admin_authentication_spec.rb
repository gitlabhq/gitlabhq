# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnforcesAdminAuthentication do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  controller(ApplicationController) do
    include EnforcesAdminAuthentication

    def index
      head :ok
    end
  end

  describe '.authorize!' do
    controller(ApplicationController) do
      include EnforcesAdminAuthentication

      authorize! :ability, only: :index

      def index
        head :ok
      end
    end

    context 'when the user is an admin', :enable_admin_mode do
      let(:user) { create(:admin) }

      it 'renders ok' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the user is a regular user' do
      it 'renders a 404' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when an ability grants access' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :ability, :global).and_return(true)
        end

        it 'renders ok' do
          get :index

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  context 'application setting :admin_mode is enabled' do
    describe 'authenticate_admin!' do
      context 'as an admin' do
        let(:user) { create(:admin) }

        it 'renders redirect for re-authentication and does not set admin mode' do
          get :index

          expect(response).to redirect_to new_admin_session_path
          expect(assigns(:current_user_mode)&.admin_mode?).to be(false)
        end

        context 'when admin mode is active', :enable_admin_mode do
          it 'renders ok' do
            get :index

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'as a user' do
        it 'renders a 404' do
          get :index

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not set admin mode' do
          get :index

          # check for nil too since on 404, current_user_mode might not be initialized
          expect(assigns(:current_user_mode)&.admin_mode?).to be_falsey
        end
      end
    end
  end

  context 'application setting :admin_mode is disabled' do
    before do
      stub_application_setting(admin_mode: false)
    end

    describe 'authenticate_admin!' do
      before do
        get :index
      end

      context 'as an admin' do
        let(:user) { create(:admin) }

        it 'allows direct access to page' do
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'does not set admin mode' do
          expect(assigns(:current_user_mode)&.admin_mode?).to be_falsey
        end
      end

      context 'as a user' do
        it 'renders a 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not set admin mode' do
          # check for nil too since on 404, current_user_mode might not be initialized
          expect(assigns(:current_user_mode)&.admin_mode?).to be_falsey
        end
      end
    end
  end
end
