# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Pipelines::StagesController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:downstream_project) { create(:project, :repository) }

  before do
    sign_in(user)
  end

  describe 'POST #play_manual.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:stage_name) { 'test' }

    before do
      create_manual_build(pipeline, 'test', 'rspec 1/2')
      create_manual_build(pipeline, 'test', 'rspec 2/2')
      create_manual_bridge(pipeline, 'test', 'trigger')

      pipeline.reload
    end

    context 'when user does not have access' do
      it 'returns not authorized' do
        play_manual_stage!

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user has access' do
      before do
        project.add_maintainer(user)
        downstream_project.add_maintainer(user)
      end

      context 'when the stage does not exists' do
        let(:stage_name) { 'deploy' }

        it 'fails to play all manual' do
          play_manual_stage!

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the stage exists' do
        it 'starts all manual jobs' do
          expect(pipeline.processables.manual.count).to eq(3)

          play_manual_stage!

          expect(response).to have_gitlab_http_status(:ok)
          expect(pipeline.processables.manual.count).to eq(0)
        end
      end
    end

    def play_manual_stage!
      post :play_manual, params: {
        namespace_id: project.namespace,
        project_id: project,
        pipeline_id: pipeline.id,
        stage_name: stage_name
      }, format: :json
    end

    def create_manual_build(pipeline, stage, name)
      create(:ci_build, :manual, pipeline: pipeline, stage: stage, name: name)
    end

    def create_manual_bridge(pipeline, stage, name)
      create(:ci_bridge, :manual, pipeline: pipeline, stage: stage, name: name, downstream: downstream_project)
    end
  end
end
