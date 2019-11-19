# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class Issue < Group::Base
          attr_reader :group, :current_user, :options

          def initialize(group:, current_user:, options:)
            @group = group
            @current_user = current_user
            @options = options
          end

          def title
            n_('New Issue', 'New Issues', value)
          end

          def value
            @value ||= find_issues
          end

          private

          def find_issues
            issues = IssuesFinder.new(current_user, finder_params).execute
            issues = issues.where(projects: { id: options[:projects] }) if options[:projects]
            issues.count
          end

          def finder_params
            {
              group_id: group.id,
              include_subgroups: true,
              created_after: options[:from],
              created_before: options[:to]
            }.compact
          end
        end
      end
    end
  end
end
