# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CycleAnalyticsController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context "counting page views for 'show'" do
    it 'increases the counter' do
      expect(Gitlab::UsageDataCounters::CycleAnalyticsCounter).to receive(:count).with(:views)

      get(:show,
          params: {
            namespace_id: project.namespace,
            project_id: project
          })

      expect(response).to be_successful
    end
  end

  context 'tracking visits to html page' do
    it_behaves_like 'tracking unique visits', :show do
      let(:request_params) { { namespace_id: project.namespace, project_id: project } }
      let(:target_id) { 'p_analytics_valuestream' }
    end
  end

  describe 'value stream analytics not set up flag' do
    context 'with no data' do
      it 'is true' do
        get(:show,
            params: {
              namespace_id: project.namespace,
              project_id: project
            })

        expect(response).to be_successful
        expect(assigns(:cycle_analytics_no_data)).to eq(true)
      end
    end

    context 'with data' do
      before do
        issue = create(:issue, project: project, created_at: 4.days.ago)
        milestone = create(:milestone, project: project, created_at: 5.days.ago)
        issue.update(milestone: milestone)

        create_merge_request_closing_issue(user, project, issue)
      end

      it 'is false' do
        get(:show,
            params: {
              namespace_id: project.namespace,
              project_id: project
            })

        expect(response).to be_successful
        expect(assigns(:cycle_analytics_no_data)).to eq(false)
      end
    end
  end

  include_examples GracefulTimeoutHandling
end
