# frozen_string_literal: true

module EarlyAccessProgram
  class TrackingEvent < ::EarlyAccessProgram::Base
    EVENT_NAME_ALLOWLIST = %w[
      g_edit_by_snippet_ide
      merge_request_action
    ].freeze

    belongs_to :user, inverse_of: :early_access_program_tracking_events

    validates :event_name, inclusion: { in: EVENT_NAME_ALLOWLIST }
  end
end
