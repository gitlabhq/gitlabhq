# frozen_string_literal: true

module Ci
  module Pipelines
    class CreatePersistentRefService
      TIMEOUT = 1.hour
      CACHE_KEY = 'pipeline:%{id}:create_persistent_ref_service'

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        if Feature.enabled?(:ci_only_one_persistent_ref_creation, pipeline.project)
          # NOTE: caching here is to prevent overwhelming calls to Gitaly API
          # triggered by the job transition to `running` in the same pipeline
          Rails.cache.fetch(pipeline_persistent_ref_cache_key, expires_in: TIMEOUT) do
            next true if persistent_ref.exist?
            next true if persistent_ref.create

            pipeline.drop!(:pipeline_ref_creation_failure)
            false
          end
        else
          return if persistent_ref.exist?

          persistent_ref.create
        end
      end

      protected

      attr_reader :pipeline

      delegate :persistent_ref, to: :pipeline

      def pipeline_persistent_ref_cache_key
        format(CACHE_KEY, id: pipeline.id)
      end
    end
  end
end
