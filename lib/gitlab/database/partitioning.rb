# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      def self.register_models(models)
        registered_models.merge(models)
      end

      def self.registered_models
        @registered_models ||= Set.new
      end

      def self.sync_partitions(models_to_sync = registered_models)
        MultiDatabasePartitionManager.new(models_to_sync).sync_partitions
      end

      def self.drop_detached_partitions
        MultiDatabasePartitionDropper.new.drop_detached_partitions
      end
    end
  end
end
