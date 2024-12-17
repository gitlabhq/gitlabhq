# frozen_string_literal: true

module Environments
  class RecalculateAutoStopWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :environment_management

    def perform(job_id, options = {})
      relation = Ci::Processable.all
      relation = relation.in_partition(options['partition_id']) if options['partition_id'].present?

      relation.find_by_id(job_id).try do |job|
        Environments::RecalculateAutoStopService.new(job).execute
      end
    end
  end
end
