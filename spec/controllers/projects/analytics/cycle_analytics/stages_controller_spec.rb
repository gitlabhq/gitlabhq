# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::StagesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:params) do
    {
      namespace_id: group,
      project_id: project,
      value_stream_id: Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME
    }
  end

  before do
    sign_in(user)
  end

  shared_examples 'project-level value stream analytics endpoint' do
    before do
      project.add_developer(user)
    end

    it 'succeeds' do
      get action, params: params

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'project-level value stream analytics request error examples' do
    context 'when invalid value stream id is given' do
      before do
        params[:value_stream_id] = 1
      end

      it 'renders 404' do
        get action, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not member of the project' do
      it 'renders 404' do
        get action, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'project-level value stream analytics with guest user' do
    let_it_be(:guest) { create(:user) }

    before do
      project.add_guest(guest)
      sign_out(user)
      sign_in(guest)
    end

    %w[code review].each do |id|
      it "disallows stage #{id}" do
        get action, params: params.merge(id: id)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    %w[issue plan test staging].each do |id|
      it "allows stage #{id}" do
        get action, params: params.merge(id: id)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET index' do
    let(:action) { :index }

    it_behaves_like 'project-level value stream analytics endpoint' do
      it 'exposes the default stages' do
        get action, params: params

        expect(json_response['stages'].size).to eq(Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size)
      end

      context 'when list service fails' do
        it 'renders 403' do
          expect_next_instance_of(Analytics::CycleAnalytics::Stages::ListService) do |list_service|
            expect(list_service).to receive(:allowed?).and_return(false)
          end

          get action, params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    it_behaves_like 'project-level value stream analytics request error examples'

    it 'only returns authorized stages' do
      guest = create(:user)
      sign_out(user)
      sign_in(guest)
      project.add_guest(guest)

      get action, params: params

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['stages'].map { |stage| stage['title'] })
        .to contain_exactly('Issue', 'Plan', 'Test', 'Staging')
    end
  end

  describe 'GET median' do
    let(:action) { :median }

    before do
      params[:id] = 'issue'
    end

    it_behaves_like 'project-level value stream analytics endpoint' do
      it 'returns the median' do
        result = 2

        expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::Median) do |instance|
          expect(instance).to receive(:seconds).and_return(result)
        end

        get action, params: params

        expect(json_response['value']).to eq(result)
      end
    end

    it_behaves_like 'project-level value stream analytics request error examples'

    it_behaves_like 'project-level value stream analytics with guest user'
  end

  describe 'GET average' do
    let(:action) { :average }

    before do
      params[:id] = 'issue'
    end

    it_behaves_like 'project-level value stream analytics endpoint' do
      it 'returns the average' do
        result = 2

        expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::Average) do |instance|
          expect(instance).to receive(:seconds).and_return(result)
        end

        get action, params: params

        expect(json_response['value']).to eq(result)
      end
    end

    it_behaves_like 'project-level value stream analytics request error examples'

    it_behaves_like 'project-level value stream analytics with guest user'
  end

  describe 'GET count' do
    let(:action) { :count }

    before do
      params[:id] = 'issue'
    end

    it_behaves_like 'project-level value stream analytics endpoint' do
      it 'returns the count' do
        count = 2

        expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::DataCollector) do |instance|
          expect(instance).to receive(:count).and_return(count)
        end

        get action, params: params

        expect(json_response['count']).to eq(count)
      end
    end

    it_behaves_like 'project-level value stream analytics request error examples'

    it_behaves_like 'project-level value stream analytics with guest user'
  end

  describe 'GET records' do
    let(:action) { :records }

    before do
      params[:id] = 'issue'
    end

    it_behaves_like 'project-level value stream analytics endpoint' do
      it 'returns the records' do
        result = Issue.none.page(1)

        expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::RecordsFetcher) do |instance|
          expect(instance).to receive(:serialized_records).and_yield(result).and_return([])
        end

        get action, params: params

        expect(json_response).to eq([])
      end
    end

    it_behaves_like 'project-level value stream analytics request error examples'

    it_behaves_like 'project-level value stream analytics with guest user'
  end
end
