# frozen_string_literal: true

module Environments
  class StopStaleService < BaseService
    def execute
      return ServiceResponse.error(message: 'Before date must be provided') unless params[:before].present?

      return ServiceResponse.error(message: 'Unauthorized') unless can?(current_user, :stop_environment, project)

      Environment.available
      .deployed_and_updated_before(project.id, params[:before])
      .without_protected(project)
      .in_batches(of: 100) do |env_batch| # rubocop:disable Cop/InBatches
        Environments::AutoStopWorker.bulk_perform_async_with_contexts(
          env_batch,
          arguments_proc: ->(environment) { environment.id },
          context_proc: ->(environment) { { project: project } }
        )
      end

      ServiceResponse.success(message: 'Successfully requested stop for all stale environments')
    end
  end
end
