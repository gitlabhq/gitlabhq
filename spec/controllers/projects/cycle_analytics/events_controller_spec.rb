# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CycleAnalytics::EventsController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'value stream analytics not set up flag' do
    context 'with no data' do
      it 'is empty' do
        get_issue

        expect(response).to be_successful
        expect(Gitlab::Json.parse(response.body)['events']).to be_empty
      end
    end

    context 'with data' do
      let(:milestone) { create(:milestone, project: project, created_at: 10.days.ago) }
      let(:issue) { create(:issue, project: project, created_at: 9.days.ago) }

      before do
        issue.update!(milestone: milestone)
      end

      it 'is not empty' do
        get_issue

        expect(response).to be_successful
      end

      it 'contains event detais' do
        get_issue

        events = Gitlab::Json.parse(response.body)['events']

        expect(events).not_to be_empty
        expect(events.first).to include('title', 'author', 'iid', 'total_time', 'created_at', 'url')
        expect(events.first['title']).to eq(issue.title)
      end

      context 'with data older than start date' do
        it 'is empty' do
          get_issue(additional_params: { cycle_analytics: { start_date: 7 } })

          expect(response).to be_successful

          expect(Gitlab::Json.parse(response.body)['events']).to be_empty
        end
      end
    end
  end

  include_examples GracefulTimeoutHandling

  def get_issue(additional_params: {})
    params = additional_params.merge(namespace_id: project.namespace, project_id: project)
    get(:issue, params: params, format: :json)
  end
end
