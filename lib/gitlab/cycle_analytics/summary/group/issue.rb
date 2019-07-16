# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class Issue < Group::Base
          def initialize(group:, from:, current_user:)
            @group = group
            @from = from
            @current_user = current_user
          end

          def title
            n_('New Issue', 'New Issues', value)
          end

          def value
            @value ||= IssuesFinder.new(@current_user, group_id: @group.id, include_subgroups: true, created_after: @from).execute.count
          end
        end
      end
    end
  end
end
