require 'spec_helper'

describe Gitlab::Metrics::MultiFileEditor do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, project.repository.commit('HEAD')) }

  before do
    stub_licensed_features(ide: true)

    allow(Digest::SHA256).to receive(:hexdigest).and_return('abcd')
  end

  describe '.record' do
    it 'records the metrics' do
      expect { subject.record }.to change { WebIdeMetric.count }.from(0).to(1)
    end

    describe 'metrics' do
      before do
        subject.record
      end

      it 'has the right project' do
        expect(WebIdeMetric.first.project).to eq('abcd')
      end

      it 'has the right user' do
        expect(WebIdeMetric.first.user).to eq('abcd')
      end

      it 'has the right line count' do
        expect(WebIdeMetric.first.line_count).to eq(1)
      end

      it 'has the right file count' do
        expect(WebIdeMetric.first.file_count).to eq(1)
      end

      it 'has the created at timestamp' do
        expect(WebIdeMetric.first.created_at).to be_a(Time)
      end
    end
  end
end
