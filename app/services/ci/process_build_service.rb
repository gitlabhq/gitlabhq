# frozen_string_literal: true

module Ci
  class ProcessBuildService < BaseService
    def execute(build, current_status)
      if valid_statuses_for_build(build).include?(current_status)
        if build.schedulable?
          build.schedule
        elsif build.action?
          build.actionize
        else
          enqueue(build)
        end

        true
      else
        build.skip
        false
      end
    end

    private

    def enqueue(build)
      build.enqueue
    end

    def valid_statuses_for_build(build)
      if ::Feature.enabled?(:skip_dag_manual_and_delayed_jobs, build.project, default_enabled: :yaml)
        current_valid_statuses_for_build(build)
      else
        legacy_valid_statuses_for_build(build)
      end
    end

    def current_valid_statuses_for_build(build)
      case build.when
      when 'on_success', 'manual', 'delayed'
        build.scheduling_type_dag? ? %w[success] : %w[success skipped]
      when 'on_failure'
        %w[failed]
      when 'always'
        %w[success failed skipped]
      else
        []
      end
    end

    def legacy_valid_statuses_for_build(build)
      case build.when
      when 'on_success'
        build.scheduling_type_dag? ? %w[success] : %w[success skipped]
      when 'on_failure'
        %w[failed]
      when 'always'
        %w[success failed skipped]
      when 'manual'
        %w[success skipped]
      when 'delayed'
        %w[success skipped]
      else
        []
      end
    end
  end
end

Ci::ProcessBuildService.prepend_if_ee('EE::Ci::ProcessBuildService')
