# frozen_string_literal: true

require 'spec_helper'

describe EnforcesAdminAuthentication do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  controller(ApplicationController) do
    # `described_class` is not available in this context
    include EnforcesAdminAuthentication # rubocop:disable RSpec/DescribedClass

    def index
      head :ok
    end
  end

  describe 'authenticate_admin!' do
    context 'as an admin' do
      let(:user) { create(:admin) }

      it 'renders ok' do
        get :index

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'as a user' do
      it 'renders a 404' do
        get :index

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
