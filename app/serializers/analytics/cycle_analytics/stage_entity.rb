# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageEntity < Grape::Entity
      include ActionView::Context
      include LabelsHelper
      include ActionView::Helpers::TagHelper

      expose :title
      expose :hidden
      expose :legend
      expose :description
      expose :id
      expose :custom

      # new API
      expose :start_event do
        expose :start_event_identifier, as: :identifier, if: ->(s) { s.custom? }
        expose :start_event_label, as: :label, using: LabelEntity, if: ->(s) { s.start_event_label_based? }
        expose :start_event_html_description, as: :html_description
      end

      expose :end_event do
        expose :end_event_identifier, as: :identifier, if: ->(s) { s.custom? }
        expose :end_event_label, as: :label, using: LabelEntity, if: ->(s) { s.end_event_label_based? }
        expose :end_event_html_description, as: :html_description
      end

      # old API
      expose :start_event_identifier, if: ->(s) { s.custom? }
      expose :end_event_identifier, if: ->(s) { s.custom? }
      expose :start_event_label, using: LabelEntity, if: ->(s) { s.start_event_label_based? }
      expose :end_event_label, using: LabelEntity, if: ->(s) { s.end_event_label_based? }
      expose :start_event_html_description
      expose :end_event_html_description

      def id
        object.id || object.name
      end

      def start_event_html_description
        html_description(object.start_event)
      end

      def end_event_html_description
        html_description(object.end_event)
      end

      # Avoid including ActionView::Helpers::UrlHelper
      def link_to(...)
        ActionController::Base.helpers.link_to(...)
      end

      private

      def html_description(event)
        options = {}
        if event.label_based?
          label = event.label.present(issuable_subject: event.label.subject)
          options[:label_html] = render_label(label, link: '', tooltip: true)
        end

        content_tag(:p) { event.html_description(options).html_safe }
      end
    end
  end
end
