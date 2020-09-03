# frozen_string_literal: true

module Ci
  module PipelinesHelper
    include Gitlab::Ci::Warnings

    def pipeline_warnings(pipeline)
      return unless pipeline.warning_messages.any?

      total_warnings = pipeline.warning_messages.length
      message = warning_header(total_warnings)

      content_tag(:div, class: 'bs-callout bs-callout-warning') do
        content_tag(:details) do
          concat content_tag(:summary, message, class: 'gl-mb-2')
          warning_markdown(pipeline) { |markdown| concat markdown }
        end
      end
    end

    def warning_header(count)
      message = _("%{total_warnings} warning(s) found:") % { total_warnings: count }

      return message unless count > MAX_LIMIT

      _("%{message} showing first %{warnings_displayed}") % { message: message, warnings_displayed: MAX_LIMIT }
    end

    private

    def warning_markdown(pipeline)
      pipeline.warning_messages(limit: MAX_LIMIT).each do |warning|
        yield markdown(warning.content)
      end
    end
  end
end
