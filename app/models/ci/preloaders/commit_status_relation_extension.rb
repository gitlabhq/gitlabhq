# frozen_string_literal: true

module Ci
  module Preloaders
    # Rails' preloader raises when a record's class lacks a requested association,
    # so mixed CommitStatus relations route `preload` through CommitStatusPreloader.
    module CommitStatusRelationExtension
      # Rails hook (:nodoc:) called from exec_queries with the loaded records.
      def preload_associations(records)
        associations = preload_values
        associations += includes_values unless eager_loading?
        return if associations.empty?

        preloader = ::Ci::Preloaders::CommitStatusPreloader.new(records)

        # The pipeline's project isn't strict loading, so only non-strict relations reuse it.
        if strict_loading_value
          preloader.execute(associations, scope: ActiveRecord::Relation::StrictLoadingScope)
        else
          preloader.execute(associations, available_records: loaded_pipeline_projects(records))
        end
      end

      private

      def loaded_pipeline_projects(records)
        records.filter_map do |record|
          pipeline = record.association(:pipeline).target
          next unless pipeline

          pipeline.association(:project).target
        end.uniq(&:object_id)
      end
    end
  end
end
