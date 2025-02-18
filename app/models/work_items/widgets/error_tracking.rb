# frozen_string_literal: true

module WorkItems
  module Widgets
    class ErrorTracking < Base
      delegate :sentry_issue, to: :work_item, allow_nil: true

      delegate :sentry_issue_identifier, to: :sentry_issue, allow_nil: true
    end
  end
end
