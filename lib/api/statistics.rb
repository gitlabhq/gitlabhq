# frozen_string_literal: true

module API
  class Statistics < ::API::Base
    before { authenticated_as_admin! }

    feature_category :devops_reports

    COUNTED_ITEMS = [Project, User, Group, ForkNetworkMember, ForkNetwork, Issue,
                     MergeRequest, Note, Snippet, Key, Milestone].freeze

    desc 'Get the current application statistics' do
      success Entities::ApplicationStatistics
    end
    get "application/statistics" do
      counts = Gitlab::Database::Count.approximate_counts(COUNTED_ITEMS)
      present counts, with: Entities::ApplicationStatistics
    end
  end
end
