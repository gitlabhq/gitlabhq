# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    module Pipeline
      ##
      # Class that represents a pipeline badge template.
      #
      # Template object will be passed to badge.svg.erb template.
      #
      class Template < Badge::Template
        STATUS_RENAME = { 'success' => 'passed' }.freeze
        STATUS_COLOR = {
          created: '#9f9f9f',
          waiting_for_resource: '#9f9f9f',
          preparing: '#9f9f9f',
          waiting_for_callback: '#9f9f9f',
          pending: '#d99530',
          running: '#428fdc',
          failed: '#dd2b0e',
          success: '#2da160',
          canceling: '#737278',
          canceled: '#737278',
          skipped: '#9f9f9f',
          manual: '#737278',
          scheduled: '#9f9f9f',
          unknown: '#9f9f9f'
        }.freeze

        def initialize(badge)
          @status = badge.status
          super
        end

        def value_text
          STATUS_RENAME[@status.to_s] || @status.to_s
        end

        def value_width
          54
        end

        def value_color
          STATUS_COLOR[@status.to_sym] || STATUS_COLOR[:unknown]
        end
      end
    end
  end
end
