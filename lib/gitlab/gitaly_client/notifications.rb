module Gitlab
  module GitalyClient
    class Notifications
      attr_accessor :stub

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @stub = GitalyClient.stub(:notifications, repository.storage)
      end

      def post_receive
        request = Gitaly::PostReceiveRequest.new(repository: @gitaly_repo)
        @stub.post_receive(request)
      end
    end
  end
end
