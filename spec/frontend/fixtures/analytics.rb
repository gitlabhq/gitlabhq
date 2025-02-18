# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Analytics (JavaScript fixtures)', :sidekiq_inline do
  include_context 'Analytics fixtures shared context'

  let_it_be(:value_stream_id) { 'default' }

  before do
    update_metrics
    create_deployment
  end

  describe Projects::Analytics::CycleAnalytics::StagesController, type: :controller do
    render_views

    let(:params) { { namespace_id: group, project_id: project, value_stream_id: value_stream_id } }

    before do
      project.add_developer(user)

      sign_in(user)
    end

    it 'projects/analytics/value_stream_analytics/stages.json' do
      get(:index, params: params, format: :json)

      expect(response).to be_successful
    end
  end

  describe Projects::CycleAnalytics::EventsController, type: :controller do
    render_views
    let(:params) { { namespace_id: group, project_id: project, value_stream_id: value_stream_id } }

    before do
      project.add_developer(user)

      sign_in(user)
    end

    Gitlab::Analytics::CycleAnalytics::DefaultStages.all.each do |stage|
      it "projects/analytics/value_stream_analytics/events/#{stage[:name]}.json" do
        get(stage[:name], params: params, format: :json)

        expect(response).to be_successful
      end
    end
  end
end
