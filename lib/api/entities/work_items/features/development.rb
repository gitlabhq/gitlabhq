# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Development < Grape::Entity
          # Only the count is exposed for now. The listing page renders a "closing merge requests" icon from this
          # number. The full closing merge request list is tracked separately in
          # https://gitlab.com/gitlab-org/gitlab/-/issues/601071.
          expose :closing_merge_requests_count, documentation: { type: 'Integer', example: 2 } do |widget, options|
            options.dig(:closing_merge_requests_counts, widget.work_item.id) || 0
          end

          expose :will_auto_close_by_merge_request,
            documentation: { type: 'Boolean', example: false } do |widget, options|
            options[:will_auto_close_ids]&.include?(widget.work_item.id) || false
          end
        end
      end
    end
  end
end
