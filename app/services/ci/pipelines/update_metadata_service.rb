# frozen_string_literal: true

module Ci
  module Pipelines
    class UpdateMetadataService
      def initialize(pipeline, current_user:, params: {})
        @pipeline = pipeline
        @current_user = current_user
        @params = params
      end

      def execute
        return forbidden unless allowed?

        metadata = pipeline.pipeline_metadata
        metadata = pipeline.build_pipeline_metadata(project: pipeline.project) if metadata.nil?
        params[:name] = params[:name].strip if params.key?(:name)

        if metadata.update(params)
          ServiceResponse.success(message: 'Pipeline metadata was updated', payload: pipeline)
        else
          ServiceResponse.error(message: 'Failed to update pipeline', payload: metadata.errors.full_messages,
            reason: :bad_request)
        end
      end

      private

      attr_reader :pipeline, :current_user, :params

      def allowed?
        ::Ability.allowed?(current_user, :update_pipeline, pipeline)
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', reason: :forbidden)
      end
    end
  end
end
