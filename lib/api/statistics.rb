# frozen_string_literal: true

module API
  class Statistics < ::API::Base
    before { authorize_read_application_statistics! }

    feature_category :devops_reports

    COUNTED_ITEMS = [Project, User, Group, ForkNetworkMember, ForkNetwork, Issue,
      MergeRequest, Note, Snippet, Key, Milestone].freeze

    desc 'Retrieve application statistics' do
      detail 'Retrieves the current application statistics for this GitLab instance.'
      success code: 200, model: Entities::ApplicationStatistics
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' }
      ]
      tags %w[instance]
    end
    route_setting :authorization, permissions: :read_statistic, boundary_type: :instance
    get "application/statistics", urgency: :low do
      counts = Gitlab::Database::Count.approximate_counts(COUNTED_ITEMS)
      present counts, with: Entities::ApplicationStatistics
    end
  end
end
