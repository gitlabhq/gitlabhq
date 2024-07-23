# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ExportJobFinder do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:project_export_job1) { create(:project_export_job, project: project, user: user) }
  let(:project_export_job2) { create(:project_export_job, project: project, user: user) }

  describe '#execute' do
    subject { described_class.new(project, user, params).execute }

    context 'when queried for a project' do
      let(:params) { {} }

      it 'scopes to the project' do
        expect(subject).to contain_exactly(
          project_export_job1, project_export_job2
        )
      end
    end

    context 'when queried by job id' do
      let(:params) { { jid: project_export_job1.jid } }

      it 'filters records' do
        expect(subject).to contain_exactly(project_export_job1)
      end
    end

    context 'when queried by status' do
      let(:params) { { status: :started } }

      before do
        project_export_job2.start!
      end

      it 'filters records' do
        expect(subject).to contain_exactly(project_export_job2)
      end
    end

    context 'when queried by invalid status' do
      let(:params) { { status: '1234ad' } }

      it 'raises exception' do
        expect { subject }.to raise_error(described_class::InvalidExportJobStatusError, 'Invalid export job status')
      end
    end
  end
end
