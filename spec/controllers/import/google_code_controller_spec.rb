require 'spec_helper'

describe Import::GoogleCodeController do
  let(:user) { create(:user) }
  let(:dump_file) { fixture_file_upload(Rails.root + 'spec/fixtures/GoogleCodeProjectHosting.json', 'application/json') }

  before do
    sign_in(user)
  end

  describe "POST callback" do
    it "stores Google Takeout dump list in session" do
      post :callback, dump_file: dump_file

      expect(session[:google_code_dump]).to be_a(Hash)
      expect(session[:google_code_dump]["kind"]).to eq("projecthosting#user")
      expect(session[:google_code_dump]).to have_key("projects")
    end
  end

  describe "GET status" do
    before do
      @repo = OpenStruct.new(name: 'vim')
      controller.stub_chain(:client, :valid?).and_return(true)
    end

    it "assigns variables" do
      @project = create(:project, import_type: 'google_code', creator_id: user.id)
      controller.stub_chain(:client, :repos).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it "does not show already added project" do
      @project = create(:project, import_type: 'google_code', creator_id: user.id, import_source: 'vim')
      controller.stub_chain(:client, :repos).and_return([@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end
end
