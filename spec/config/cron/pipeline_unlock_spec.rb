require 'spec_helper'

describe Settings do
  describe 'cron jobs' do
    describe 'pipeline unlock worker' do
      subject do
        described_class.cron_jobs[:pipeline_unlock_worker]
      end

      it 'is scheduled hourly' do
        expect(subject.cron).to eq '40 * * * *'
      end

      it 'is tied to proper class' do
        expect(subject.job_class).to eq 'PipelineUnlockWorker'
      end
    end
  end
end
