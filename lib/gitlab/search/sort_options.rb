# frozen_string_literal: true

module Gitlab
  module Search
    module SortOptions
      SCOPE_ONLY_SORT = {
        popularity_asc: %w[issues],
        popularity_desc: %w[issues]
      }.freeze

      DOC_TYPE_ONLY_SORT = {
        popularity_asc: %w[issue work_item],
        popularity_desc: %w[issue work_item]
      }.freeze

      SORT_MAPPINGS = {
        # order_by + sort combinations
        %w[created_at asc] => :created_at_asc,
        %w[created_at desc] => :created_at_desc,
        %w[updated_at asc] => :updated_at_asc,
        %w[updated_at desc] => :updated_at_desc,
        %w[popularity asc] => :popularity_asc,
        %w[popularity desc] => :popularity_desc,
        %w[milestone_due asc] => :milestone_due_asc,
        %w[milestone_due desc] => :milestone_due_desc,
        %w[weight asc] => :weight_asc,
        %w[weight desc] => :weight_desc,
        %w[health_status asc] => :health_status_asc,
        %w[health_status desc] => :health_status_desc,
        %w[closed_at asc] => :closed_at_asc,
        %w[closed_at desc] => :closed_at_desc,
        %w[due_date asc] => :due_date_asc,
        %w[due_date desc] => :due_date_desc,
        # sort only combinations
        [nil, 'created_asc'] => :created_at_asc,
        [nil, 'created_desc'] => :created_at_desc,
        [nil, 'updated_asc'] => :updated_at_asc,
        [nil, 'updated_desc'] => :updated_at_desc,
        [nil, 'popularity_asc'] => :popularity_asc,
        [nil, 'popularity_desc'] => :popularity_desc,
        [nil, 'milestone_due_asc'] => :milestone_due_asc,
        [nil, 'milestone_due_desc'] => :milestone_due_desc,
        [nil, 'weight_asc'] => :weight_asc,
        [nil, 'weight_desc'] => :weight_desc,
        [nil, 'health_status_asc'] => :health_status_asc,
        [nil, 'health_status_desc'] => :health_status_desc,
        [nil, 'closed_at_asc'] => :closed_at_asc,
        [nil, 'closed_at_desc'] => :closed_at_desc,
        [nil, 'due_date_asc'] => :due_date_asc,
        [nil, 'due_date_desc'] => :due_date_desc
      }.freeze

      def sort_and_direction(order_by, sort)
        # Due to different uses of sort param in web vs. API requests we prefer
        # order_by when present
        SORT_MAPPINGS.fetch([order_by, sort], :unknown)
      end
      module_function :sort_and_direction
    end
  end
end
