# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Deploy < Base
        include Gitlab::Utils::StrongMemoize

        def title
          n_('Deploy', 'Deploys', value)
        end

        def value
          strong_memoize(:value) do
            query = @project.deployments.success.where("created_at >= ?", @from)
            query = query.where("created_at <= ?", @to) if @to
            query.count
          end
        end
      end
    end
  end
end
