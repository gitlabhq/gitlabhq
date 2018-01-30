require 'spec_helper'

describe Gitlab::Metrics::MultiFileEditor do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:params) do
    [
      :multi_file_editor_usage,
      'Total number of commits using the multi-file web editor',
      {
        project: 'abcd',
        user: 'abcd',
        line_changes: 1,
        files_count: 1
      }
    ]
  end

  subject { described_class.new(project, user, project.repository.commit('HEAD')) }

  before do
    allow(Digest::SHA256).to receive(:hexdigest).and_return('abcd')
  end

  describe '.record' do
    it 'records the right metrics' do
      expect(::Gitlab::Metrics).to receive(:counter).with(*params)

      subject.record
    end
  end
end
