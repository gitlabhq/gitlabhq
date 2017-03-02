module Gitlab
  module GitalyClient
    class Notifications
      attr_accessor :stub

      def initialize
        @stub = Gitaly::Notifications::Stub.new(nil, nil, channel_override: GitalyClient.channel)
      end

      def post_receive(repo_path)
        repository = Gitaly::Repository.new(path: repo_path)
        request = Gitaly::PostReceiveRequest.new(repository: repository)
        stub.post_receive(request)
      end
    end
  end
end
