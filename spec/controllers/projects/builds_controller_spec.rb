require 'spec_helper'

describe Projects::BuildsController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    context 'number of queries' do
      before do
        Ci::Build::AVAILABLE_STATUSES.each do |status|
          create_build(status, status)
        end

        RequestStore.begin!
      end

      after do
        RequestStore.end!
        RequestStore.clear!
      end

      def render
        get :index, namespace_id: project.namespace,
                    project_id: project
      end

      it "verifies number of queries" do
        recorded = ActiveRecord::QueryRecorder.new { render }
        expect(recorded.count).to be_within(5).of(8)
      end

      def create_build(name, status)
        pipeline = create(:ci_pipeline, project: project)
        create(:ci_build, :tags, :triggered, :artifacts,
          pipeline: pipeline, name: name, status: status)
      end
    end
  end

  describe 'GET status.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:status) { build.detailed_status(double('user')) }

    before do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: build.id,
                   format: :json
    end

    it 'return a detailed build status in json' do
      expect(response).to have_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to match status.favicon
    end
  end
end
