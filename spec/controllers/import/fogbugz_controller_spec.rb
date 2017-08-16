require 'spec_helper'

describe Import::FogbugzController do
  include ImportSpecHelper

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET status' do
    before do
      @repo = OpenStruct.new(name: 'vim')
      stub_client(valid?: true)
    end

    it 'assigns variables' do
      @project = create(:project, import_type: 'fogbugz', creator_id: user.id)
      stub_client(repos: [@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it 'does not show already added project' do
      @project = create(:project, import_type: 'fogbugz', creator_id: user.id, import_source: 'vim')
      stub_client(repos: [@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end
end
