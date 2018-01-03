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
  end

  describe 'GET merge requests' do
    it_behaves_like 'issuables list meta-data', :merge_request, :merge_requests
  end
end
