# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Cache
      class DestroyOrphanEntriesWorker
        include ApplicationWorker
        include CronjobChildWorker
        include LimitedCapacity::Worker

        MAX_CAPACITY = 2
        REMAINING_WORK_COUNT = 0

        data_consistency :sticky
        urgency :low
        idempotent!

        queue_namespace :dependency_proxy_blob
        feature_category :virtual_registry

        # overridden in EE
        def perform_work(_model)
          # no-op
        end

        def remaining_work_count(_model)
          REMAINING_WORK_COUNT
        end

        def max_running_jobs
          MAX_CAPACITY
        end
      end
    end
  end
end

VirtualRegistries::Packages::Cache::DestroyOrphanEntriesWorker.prepend_mod
