require 'spec_helper'

describe Dashboard::ProjectsController do
  it_behaves_like 'authenticates sessionless user', :index, :atom

  context 'json requests' do
    render_views

    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    describe 'GET /projects.json' do
      before do
        get :index, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end

    describe 'GET /starred.json' do
      before do
        get :starred, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end
  end
end
