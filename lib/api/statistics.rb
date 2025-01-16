# frozen_string_literal: true

module API
  class Statistics < ::API::Base
    before { authorize_read_application_statistics! }

    feature_category :devops_reports

    COUNTED_ITEMS = [Project, User, Group, ForkNetworkMember, ForkNetwork, Issue,
                     MergeRequest, Note, Snippet, Key, Milestone].freeze

    desc 'Get the current application statistics' do
      success code: 200, model: Entities::ApplicationStatistics
    end
    get "application/statistics", urgency: :low do
      counts = Gitlab::Database::Count.approximate_counts(COUNTED_ITEMS)
      present counts, with: Entities::ApplicationStatistics
    end
  end
end
