require 'spec_helper'

describe Dashboard::LabelsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let!(:label)  { create(:label, project: project) }

  before do
    sign_in(user)
    project.add_reporter(user)
  end

  describe "#index" do
    let!(:unrelated_label) { create(:label, project: create(:project, :public)) }

    it 'returns global labels for projects the user has a relationship with' do
      get :index, format: :json

      expect(json_response).to be_kind_of(Array)
      expect(json_response.size).to eq(1)
      expect(json_response[0]["id"]).to be_nil
      expect(json_response[0]["title"]).to eq(label.title)
    end
  end
end
