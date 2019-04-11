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

  describe "#check_filters_presence!" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
      get :merge_requests, params: params
    end

    context "no filters" do
      let(:params) { {} }

      it 'sets @no_filters_set to false' do
        expect(assigns[:no_filters_set]).to eq(true)
      end
    end

    context "scalar filters" do
      let(:params) { { author_id: user.id } }

      it 'sets @no_filters_set to false' do
        expect(assigns[:no_filters_set]).to eq(false)
      end
    end

    context "array filters" do
      let(:params) { { label_name: ['bug'] } }

      it 'sets @no_filters_set to false' do
        expect(assigns[:no_filters_set]).to eq(false)
      end
    end
  end
end
