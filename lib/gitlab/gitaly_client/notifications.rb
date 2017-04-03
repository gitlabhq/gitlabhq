module Gitlab
  module GitalyClient
    class Notifications
      attr_accessor :stub

      def initialize(repo_path)
        full_path = Gitlab::RepoPath.strip_storage_path(repo_path).
          sub(/\.git\z/, '').sub(/\.wiki\z/, '')
        @project = Project.find_by_full_path(full_path)

        channel = GitalyClient.get_channel(@project.repository_storage)
        @stub = Gitaly::Notifications::Stub.new(nil, nil, channel_override: channel)
      end

      def post_receive
        repository = Gitaly::Repository.new(path: @project.repository.path_to_repo)
        request = Gitaly::PostReceiveRequest.new(repository: repository)
        @stub.post_receive(request)
      end
    end
  end
end
