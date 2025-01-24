# frozen_string_literal: true

module VirtualRegistries
  module Packages
    class DestroyOrphanCachedResponsesWorker < ::VirtualRegistries::Packages::Cache::DestroyOrphanEntriesWorker
      data_consistency :sticky
      urgency :low
      idempotent!

      queue_namespace :dependency_proxy_blob
      feature_category :virtual_registry
    end
  end
end
