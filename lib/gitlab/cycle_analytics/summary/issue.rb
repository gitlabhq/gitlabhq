# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Issue < Base
        def initialize(project:, options:, current_user:)
          @project = project
          @options = options
          @current_user = current_user
        end

        def identifier
          :issues
        end

        def title
          n_('New issue', 'New issues', value.to_i)
        end

        def value
          @value ||= Value::PrettyNumeric.new(issues_count)
        end

        private

        def issues_count
          IssuesFinder
            .new(@current_user, finder_params)
            .execute
            .count
        end

        def finder_params
          @options.dup.tap do |hash|
            hash[:created_after] = hash.delete(:from)
            hash[:created_before] = hash.delete(:to)
            hash[:project_id] = @project.id
          end
        end
      end
    end
  end
end
