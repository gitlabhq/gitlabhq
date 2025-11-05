# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AuthJobFinder, feature_category: :continuous_integration do
  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:job, refind: true) { create(:ci_build, status: :running, user: user) }
  let_it_be(:canceling_job, refind: true) { create(:ci_build, :canceling, user: user) }

  let(:token) { job.token }

  subject(:finder) do
    described_class.new(token: token)
  end

  describe '#execute!', :request_store do
    subject(:execute) { finder.execute! }

    it { is_expected.to eq(job) }

    context 'with a database token' do
      before do
        stub_feature_flags(ci_job_token_jwt: false)
        token # preloads the job
      end

      it { is_expected.to eq(job) }

      it 'uses partition_id as a filter' do
        recorder = ActiveRecord::QueryRecorder.new { execute }

        expect(recorder).not_to exceed_query_limit(1).for_query(/FROM "p_ci_builds"/)
        expect(recorder).not_to exceed_query_limit(1).for_query(/"p_ci_builds"."partition_id" = #{job.partition_id}/)
        expect(recorder).not_to exceed_query_limit(1).for_query(/"p_ci_builds"."token_encrypted" IN/)
      end

      context 'when the partition_id is incorrect' do
        before do
          allow(::Ci::Builds::TokenPrefix).to receive(:decode_partition).with(job.token).and_return(123)
        end

        it 'queries all partitions' do
          recorder = ActiveRecord::QueryRecorder.new { execute }

          expect(recorder).not_to exceed_query_limit(2).for_query(/FROM "p_ci_builds"/)
          expect(recorder).not_to exceed_query_limit(2).for_query(/"p_ci_builds"."token_encrypted" IN/)
          expect(recorder).not_to exceed_query_limit(1).for_query(/"p_ci_builds"."partition_id" = #{job.partition_id}/)
        end

        it { is_expected.to eq(job) }
      end

      context 'when the partition_id can not be decoded' do
        before do
          allow(::Ci::Builds::TokenPrefix).to receive(:decode_partition).with(job.token).and_return(nil)
        end

        it 'queries all partitions' do
          recorder = ActiveRecord::QueryRecorder.new { execute }

          expect(recorder).not_to exceed_query_limit(1).for_query(/FROM "p_ci_builds"/)
          expect(recorder).not_to exceed_query_limit(1).for_query(/"p_ci_builds"."token_encrypted" IN/)
          expect(recorder).not_to exceed_query_limit(0).for_query(/"p_ci_builds"."partition_id" = #{job.partition_id}/)
        end

        it { is_expected.to eq(job) }
      end
    end

    context 'when job has a `scoped_user_id` tracked' do
      let(:scoped_user) { create(:user) }

      before do
        job.update!(scoped_user_id: scoped_user.id)
      end

      context 'when job user does not support composite identity' do
        it 'does not link the scoped user as composite identity' do
          execute

          expect(::Gitlab::Auth::Identity.new(job.user)).not_to be_linked
        end
      end
    end

    it 'raises error if the job is succeeded' do
      job.success!

      expect { execute }.to raise_error described_class::NotRunningJobError, 'Job is not running'
    end

    context 'when the job is canceling' do
      let(:token) { canceling_job.token }

      it 'returns the job' do
        expect(finder.execute!).to eq(canceling_job)
      end
    end

    it 'raises error if the job is erased' do
      expect(finder).to receive(:find_job_by_token).and_return(job)
      expect(job).to receive(:erased?).and_return(true)

      expect { execute }.to raise_error described_class::ErasedJobError, 'Job has been erased!'
    end

    it 'raises error if the the project is missing' do
      expect(finder).to receive(:find_job_by_token).and_return(job)
      expect(job).to receive(:project).and_return(nil)

      expect { execute }.to raise_error described_class::DeletedProjectError, 'Project has been deleted!'
    end

    it 'raises error if the the project is being removed' do
      project = instance_double(Project)

      expect(finder).to receive(:find_job_by_token).and_return(job)
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

    context 'when job is not running' do
      before do
        job.success!
      end

      it { is_expected.to be_nil }
    end

    context 'when job is running', :request_store do
      it 'sets ci_job_token_scope on the job user', :aggregate_failures do
        expect(execute).to eq(job)
        expect(execute.user).to be_from_ci_job_token
        expect(execute.user.ci_job_token_scope.current_project).to eq(job.project)
      end

      it 'logs context data about the job' do
        expect(::Gitlab::AppLogger).to receive(:info).with a_hash_including({
          job_id: job.id,
          job_user_id: job.user_id,
          job_project_id: job.project_id
        })

        execute
      end
    end
  end
end
