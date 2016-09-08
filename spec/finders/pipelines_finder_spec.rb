require 'spec_helper'

describe PipelinesFinder do
  let(:project) { create(:project) }

  let!(:tag_pipeline)    { create(:ci_pipeline, project: project, ref: 'v1.0.0') }
  let!(:branch_pipeline) { create(:ci_pipeline, project: project) }

  subject { described_class.new(project).execute(params) }

  describe "#execute" do
    context 'when a scope is passed' do
      context 'when scope is nil' do
        let(:params) { { scope: nil } }

        it 'selects all pipelines' do
          expect(subject.count).to be 2
          expect(subject).to include tag_pipeline
          expect(subject).to include branch_pipeline
        end
      end

      context 'when selecting branches' do
        let(:params) { { scope: 'branches' } }

        it 'excludes tags' do
          expect(subject).not_to include tag_pipeline
          expect(subject).to     include branch_pipeline
        end
      end

      context 'when selecting tags' do
        let(:params) { { scope: 'tags' } }

        it 'excludes branches' do
          expect(subject).to     include tag_pipeline
          expect(subject).not_to include branch_pipeline
        end
      end
    end

    # Scoping to running will speed up the test as it doesn't hit the FS
    let(:params) { { scope: 'running' } }

    it 'orders in descending order on ID' do
      create(:ci_pipeline, project: project, ref: 'feature')

      expect(subject.map(&:id)).to eq [3, 2, 1]
    end
  end
end
