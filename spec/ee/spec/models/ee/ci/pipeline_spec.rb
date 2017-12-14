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

  ARTIFACTS_METHODS = {
    codeclimate_artifact: Ci::Build::CODEQUALITY_FILE,
    performance_artifact: Ci::Build::PERFORMANCE_FILE,
    sast_artifact: Ci::Build::SAST_FILE,
    clair_artifact: Ci::Build::CLAIR_FILE
  }.freeze

  ARTIFACTS_METHODS.each do |method, filename|
    describe method.to_s do
      context 'has corresponding job' do
        let!(:build) do
          create(
            :ci_build,
            :artifacts,
            name: method.to_s.sub('_artifact', ''),
            pipeline: pipeline,
            options: {
              artifacts: {
                paths: [filename]
              }
            }
          )
        end

        it { expect(pipeline.send(method)).to eq(build) }
      end

      context 'no codequality job' do
        before do
          create(:ci_build, pipeline: pipeline)
        end

        it { expect(pipeline.send(method)).to be_nil }
      end
    end
  end
end
