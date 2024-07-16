# frozen_string_literal: true

module API
  module Entities
    class Label < Entities::LabelBasic
      with_options if: ->(_, options) { options[:with_counts] } do
        expose :open_issues_count do |label, options|
          label.open_issues_count(options[:current_user])
        end

        expose :closed_issues_count do |label, options|
          label.closed_issues_count(options[:current_user])
        end

        expose :open_merge_requests_count do |label, options|
          label.open_merge_requests_count(options[:current_user])
        end
      end

      expose :subscribed do |label, options|
        label.subscribed?(options[:current_user]) || (
          options[:parent].is_a?(::Project) && label.subscribed?(options[:current_user], options[:parent])
        )
      end
    end
  end
end
