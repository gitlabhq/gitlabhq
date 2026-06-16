# frozen_string_literal: true

module Gitlab
  module Observability
    module CicdSemconv
      # Shared value mappings for OTel CI/CD Semantic Conventions.
      # Ref: https://opentelemetry.io/docs/specs/semconv/registry/attributes/cicd/

      PIPELINE_RESULT_MAP = {
        "success" => "success",
        "failed" => "failure",
        "canceled" => "cancellation",
        "skipped" => "skip"
      }.freeze

      PIPELINE_RUN_STATE_MAP = {
        "pending" => "pending",
        "waiting_for_resource" => "pending",
        "preparing" => "pending",
        "running" => "executing"
      }.freeze

      PIPELINE_TRIGGER_TYPE_MAP = {
        "push" => "push",
        "schedule" => "schedule",
        "web" => "manual",
        "trigger" => "manual",
        "api" => "manual",
        "merge_request_event" => "merge_request_event",
        "external_pull_request_event" => "pull_request_event",
        "pipeline" => "pipeline"
      }.freeze

      PIPELINE_TASK_TYPE_MAP = {
        "build" => "build",
        "test" => "test",
        "deploy" => "deploy"
      }.freeze

      TASK_RUN_STATE_MAP = {
        "pending" => "pending",
        "running" => "executing",
        "waiting_for_resource" => "pending"
      }.freeze

      TASK_RUN_RESULT_MAP = {
        "success" => "success",
        "failed" => "failure",
        "skipped" => "skip",
        "canceled" => "cancellation"
      }.freeze
      MR_STATE_MAP = {
        "opened" => "open",
        "closed" => "closed",
        "merged" => "merged",
        "locked" => "wip"
      }.freeze

      def map_task_run_result(status)
        TASK_RUN_RESULT_MAP[status]
      end

      def map_task_run_state(status)
        TASK_RUN_STATE_MAP[status]
      end

      def map_pipeline_result(status)
        PIPELINE_RESULT_MAP[status]
      end

      def map_pipeline_run_state(status)
        PIPELINE_RUN_STATE_MAP[status]
      end

      def map_pipeline_trigger_type(source)
        PIPELINE_TRIGGER_TYPE_MAP[source]
      end

      def map_pipeline_task_type(stage)
        PIPELINE_TASK_TYPE_MAP[stage]
      end

      def map_worker_state(active)
        active ? "available" : "offline"
      end

      def map_mr_state(state)
        MR_STATE_MAP[state]
      end

      def compact_attributes(attrs)
        attrs.compact.reject do |attr|
          value = attr[:value]
          value.key?(:stringValue) && value[:stringValue].blank?
        end
      end
    end
  end
end
