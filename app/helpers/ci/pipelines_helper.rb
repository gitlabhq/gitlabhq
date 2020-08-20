# frozen_string_literal: true

module Ci
  module PipelinesHelper
    def pipeline_warnings(pipeline)
      return unless pipeline.warning_messages.any?

      content_tag(:div, class: 'alert alert-warning') do
        content_tag(:h4, 'Warning:') <<
          content_tag(:div) do
            pipeline.warning_messages.each do |warning|
              concat(markdown(warning.content))
            end
          end
      end
    end
  end
end
