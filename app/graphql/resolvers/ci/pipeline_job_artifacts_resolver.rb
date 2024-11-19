# frozen_string_literal: true

module Resolvers
  module Ci
    class PipelineJobArtifactsResolver < BaseResolver
      type [Types::Ci::JobArtifactType], null: false

      alias_method :pipeline, :object

      def resolve
        find_job_artifacts
      end

      private

      def find_job_artifacts
        BatchLoader::GraphQL.for(pipeline).batch do |pipelines, loader|
          ActiveRecord::Associations::Preloader.new(records: pipelines, associations: :job_artifacts).call

          pipelines.each { |pl| loader.call(pl, pl.job_artifacts) }
        end
      end
    end
  end
end
