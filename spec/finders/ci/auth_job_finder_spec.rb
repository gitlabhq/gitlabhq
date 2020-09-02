# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::AuthJobFinder do
  let_it_be(:job, reload: true) { create(:ci_build, status: :running) }

  let(:token) { job.token }

  subject(:finder) do
    described_class.new(token: token)
  end

  describe '#execute!' do
    subject(:execute) { finder.execute! }

    it { is_expected.to eq(job) }

    it 'raises error if the job is not running' do
      job.success!

      expect { execute }.to raise_error described_class::NotRunningJobError, 'Job is not running'
    end

    it 'raises error if the job is erased' do
      expect(::Ci::Build).to receive(:find_by_token).with(job.token).and_return(job)
      expect(job).to receive(:erased?).and_return(true)

      expect { execute }.to raise_error described_class::ErasedJobError, 'Job has been erased!'
    end

    it 'raises error if the the project is missing' do
      expect(::Ci::Build).to receive(:find_by_token).with(job.token).and_return(job)
      expect(job).to receive(:project).and_return(nil)

      expect { execute }.to raise_error described_class::DeletedProjectError, 'Project has been deleted!'
    end

    it 'raises error if the the project is being removed' do
      project = double(Project)

      expect(::Ci::Build).to receive(:find_by_token).with(job.token).and_return(job)
      expect(job).to receive(:project).twice.and_return(project)
      expect(project).to receive(:pending_delete?).and_return(true)

      expect { execute }.to raise_error described_class::DeletedProjectError, 'Project has been deleted!'
    end

    context 'with wrong job token' do
      let(:token) { 'missing' }

      it { is_expected.to be_nil }
    end
  end

  describe '#execute' do
    subject(:execute) { finder.execute }

    before do
      job.success!
    end

    it { is_expected.to be_nil }
  end
end
