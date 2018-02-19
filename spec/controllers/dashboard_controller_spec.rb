require 'spec_helper'

describe DashboardController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET issues' do
    it_behaves_like 'issuables list meta-data', :issue, :issues

    it 'sets assignee_id when not provided' do
      get :issues

      expect(controller.params.keys).to include('assignee_id')
      expect(controller.params['assignee_id']).to eq user.id
    end
  end

  describe 'GET merge_requests' do
    it_behaves_like 'issuables list meta-data', :merge_request, :merge_requests

    it 'sets assignee_id when not provided' do
      get :merge_requests

      expect(controller.params.keys).to include('assignee_id')
      expect(controller.params['assignee_id']).to eq user.id
    end
  end
end
