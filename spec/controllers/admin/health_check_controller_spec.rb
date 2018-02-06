require 'spec_helper'

describe Admin::HealthCheckController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET show' do
    it 'loads the git storage health information' do
      get :show

      expect(assigns[:failing_storage_statuses]).not_to be_nil
    end
  end

  describe 'POST reset_storage_health' do
    it 'resets all storage health information' do
      expect(Gitlab::Git::Storage::FailureInfo).to receive(:reset_all!)

      post :reset_storage_health
    end
  end
end
