require 'spec_helper'

describe Profiles::SlacksController do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    allow(subject).to receive(:current_user).and_return(user)
  end

  describe 'GET edit' do
    before do
      get :edit
    end

    it 'renders' do
      expect(response).to render_template :edit
    end

    it 'assigns projects' do
      expect(assigns[:projects]).to eq []
    end

    it 'assigns disabled_projects' do
      expect(assigns[:disabled_projects]).to eq []
    end
  end
end
