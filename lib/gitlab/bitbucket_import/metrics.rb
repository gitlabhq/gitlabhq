# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Metrics
      extend ActiveSupport::Concern

      IMPORTER = :bitbucket_importer

      included do
        prepend Gitlab::Import::Metrics

        Gitlab::Import::Metrics.measure(:execute, metrics: {
          "#{IMPORTER}_imported_projects": {
            type: :counter,
            description: 'The number of imported Bitbucket projects'
          },
          "#{IMPORTER}_total_duration_seconds": {
            type: :histogram,
            labels: { importer: IMPORTER },
            description: 'Total time spent importing Bitbucket projects, in seconds'
          }
        })

        Gitlab::Import::Metrics.measure(:import_issue, metrics: {
          "#{IMPORTER}_imported_issues": {
            type: :counter,
            description: 'The number of imported Bitbucket issues'
          }
        })

        Gitlab::Import::Metrics.measure(:import_pull_request, metrics: {
          "#{IMPORTER}_imported_pull_requests": {
            type: :counter,
            description: 'The number of imported Bitbucket pull requests'
          }
        })
      end
    end
  end
end
