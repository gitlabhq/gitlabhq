# frozen_string_literal: true

module Ci
  class ProcessBuildService < BaseService
    def execute(processable, current_status)
      if valid_statuses_for_processable(processable).include?(current_status)
        process(processable)
        true
      else
        processable.skip
        false
      end
    end

    private

    def process(processable)
      return enqueue(processable) if processable.enqueue_immediately?

      if processable.schedulable?
        processable.schedule
      elsif processable.action?
        processable.actionize
      else
        enqueue(processable)
      end
    end

    def enqueue(processable)
      return processable.drop!(:failed_outdated_deployment_job) if processable.has_outdated_deployment?

      processable.enqueue
    end

    def valid_statuses_for_processable(processable)
      case processable.when
      when 'on_success', 'manual', 'delayed'
        processable.scheduling_type_dag? ? %w[success] : %w[success skipped]
      when 'on_failure'
        %w[failed]
      when 'always'
        %w[success failed skipped]
      else
        []
      end
    end
  end
end

Ci::ProcessBuildService.prepend_mod_with('Ci::ProcessBuildService')
