# frozen_string_literal: true

module ErrorTracking
  class ErrorEventEntity < Grape::Entity
    expose :issue_id, :date_received, :stack_trace_entries
  end
end
