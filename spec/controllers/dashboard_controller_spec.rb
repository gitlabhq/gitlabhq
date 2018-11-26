require 'spec_helper'

describe DashboardController do
  context 'signed in' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    describe 'GET issues' do
      it_behaves_like 'issuables list meta-data', :issue, :issues
      it_behaves_like 'issuables requiring filter', :issues
    end

    describe 'GET merge requests' do
      it_behaves_like 'issuables list meta-data', :merge_request, :merge_requests
      it_behaves_like 'issuables requiring filter', :merge_requests
    end
  end

  it_behaves_like 'authenticates sessionless user', :issues, :atom, author_id: User.first
  it_behaves_like 'authenticates sessionless user', :issues_calendar, :ics
end
