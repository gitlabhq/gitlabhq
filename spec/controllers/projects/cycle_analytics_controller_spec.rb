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

  include_examples GracefulTimeoutHandling
end
