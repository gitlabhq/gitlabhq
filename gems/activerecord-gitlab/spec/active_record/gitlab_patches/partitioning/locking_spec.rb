# frozen_string_literal: true

RSpec.describe 'ActiveRecord::GitlabPatches::Partitioning::Associations::Locking', :partitioning do
  let!(:job) { LockingJob.create!(partition_id: 100) }

  describe 'optimistic locking' do
    it 'does not use lock version on unrelated updates' do
      update_statement = <<~SQL.squish
        UPDATE "locking_jobs" SET "name" = 'test'
        WHERE "locking_jobs"."id" = #{job.id} AND "locking_jobs"."partition_id" = #{job.partition_id}
      SQL

      result = QueryRecorder.log do
        job.update!(name: 'test')
      end

      expect(result).to include(update_statement)
    end

    it 'uses lock version when status changes' do
      update_statement = <<~SQL.squish
        UPDATE "locking_jobs"
        SET "status" = 1, "name" = 'test', "lock_version" = 1
        WHERE "locking_jobs"."id" = 1 AND "locking_jobs"."partition_id" = 100 AND "locking_jobs"."lock_version" = 0
      SQL

      result = QueryRecorder.log do
        job.update!(name: 'test', status: :completed)
      end

      expect(result).to include(update_statement)
    end
  end
end
