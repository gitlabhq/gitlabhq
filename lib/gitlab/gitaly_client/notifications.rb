module Gitlab
  module GitalyClient
    class Notifications
      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def post_receive
        GitalyClient.call(
          @storage,
          :notifications,
          :post_receive,
          Gitaly::PostReceiveRequest.new(repository: @gitaly_repo)
        )
      end
    end
  end
end
