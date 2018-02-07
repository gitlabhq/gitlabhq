require 'spec_helper'

describe Gitlab::Metrics::MultiFileEditor do
  set(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, project.commit('b83d6e391c22777fca1ed3012fce84f633d7fed0')) }

  describe '.log' do
    it 'has the right log info' do
      stub_licensed_features(ide: true)

      info = "Web editor usage - ide_usage_project_id: #{project.id}, ide_usage_user: #{user.id}, ide_usage_line_count: 1, ide_usage_file_count: 1"

      expect(Rails.logger).to receive(:info).with(info)

      subject.log
    end

    it 'does not log any info if IDE is disabled' do
      info = "Web editor usage - ide_usage_project_id: #{project.id}, ide_usage_user: #{user.id}, ide_usage_line_count: 1, ide_usage_file_count: 1"

      expect(Rails.logger).not_to receive(:info).with(info)

      subject.log
    end
  end
end
