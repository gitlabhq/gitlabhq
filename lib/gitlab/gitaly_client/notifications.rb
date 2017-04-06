module Gitlab
  module GitalyClient
    class Notifications
      attr_accessor :stub

      def initialize(repository_storage, relative_path)
        @channel = Util.channel(repository_storage)
        @repository = Util.repository(repository_storage, relative_path)
        @stub = Gitaly::Notifications::Stub.new(nil, nil, channel_override: @channel)
      end

      def post_receive
        request = Gitaly::PostReceiveRequest.new(repository: @repository)
        @stub.post_receive(request)
      end
    end
  end
end
