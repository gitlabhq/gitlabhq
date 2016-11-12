require 'rails_helper'

RSpec.describe ChatOpsController, type: :controller do
  describe "POST #trigger" do
    it "returns http success" do
      post :trigger

      expect(response).to have_http_status(:success)
    end
  end
end
