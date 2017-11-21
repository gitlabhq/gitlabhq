require 'spec_helper'

describe Ci::Pipeline do
  let(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end

  describe '.failure_reasons' do
    it 'contains failure reasons about exceeded limits' do
      expect(described_class.failure_reasons)
        .to include 'activity_limit_exceeded', 'size_limit_exceeded'
    end
  end

  describe '#codeclimate_artifact' do
    context 'has codequality job' do
      let!(:build) do
        create(
          :ci_build,
          :artifacts,
          name: 'codequality',
          pipeline: pipeline,
          options: {
            artifacts: {
              paths: ['codeclimate.json']
            }
          }
        )
      end

      it { expect(pipeline.codeclimate_artifact).to eq(build) }
    end

    context 'no codequality job' do
      before do
        create(:ci_build, pipeline: pipeline)
      end

      it { expect(pipeline.codeclimate_artifact).to be_nil }
    end
  end

  describe '#sast_artifact' do
    context 'has sast job' do
      let!(:build) do
        create(
          :ci_build,
          :artifacts,
          name: 'sast',
          pipeline: pipeline,
          options: {
            artifacts: {
              paths: ['gl-sast-report.json']
            }
          }
        )
      end

      it { expect(pipeline.sast_artifact).to eq(build) }
    end

    context 'no sast job' do
      before do
        create(:ci_build, pipeline: pipeline)
      end

      it { expect(pipeline.sast_artifact).to be_nil }
    end
  end
end
