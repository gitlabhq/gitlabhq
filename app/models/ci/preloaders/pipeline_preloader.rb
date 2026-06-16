# frozen_string_literal: true

module Ci
  module Preloaders
    # Preloads a Ci::Pipeline association on a collection of records using a
    # partition-aware bulk lookup. After preload_all runs, accessing the
    # association on any record does not trigger an SQL query.
    #
    # Usage:
    #   merge_requests = MergeRequest.where(...).to_a
    #   Ci::Preloaders::PipelinePreloader.new(
    #     merge_requests,
    #     association: :head_pipeline,
    #     foreign_key: :head_pipeline_id
    #   ).preload_all
    #
    #   merge_requests.first.head_pipeline # no query
    class PipelinePreloader
      def initialize(records, association:, foreign_key:)
        @records = records
        @association = association
        @foreign_key = foreign_key
      end

      def preload_all
        cache = Gitlab::Ci::Pipeline::BulkByIdLookup.new(referenced_ids).execute

        records.each { |record| assign_target(record, cache[record.read_attribute(foreign_key)]) }
      end

      private

      attr_reader :records, :association, :foreign_key

      def referenced_ids
        records.filter_map { |record| record.read_attribute(foreign_key) }.uniq
      end

      def assign_target(record, target)
        record_association = record.association(association)
        record_association.target = target
        record_association.loaded!
      end
    end
  end
end
