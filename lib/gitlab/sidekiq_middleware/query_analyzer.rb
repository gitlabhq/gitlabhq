# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class QueryAnalyzer
      def call(worker, job, queue)
        ::Gitlab::Database::QueryAnalyzer.instance.within { yield }
      end
    end
  end
end
